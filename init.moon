package.path = "?.lua;?/init.lua;" .. package.path

max_particles=20000

width=800
height=600
psize=10

ffi = require 'ffi'
gl  = require 'glua'
import random,min,max from require'math'

class Particle
  new: =>
    @initValues!
  initValues: =>
    @x=random(0,width/psize)
    @y=0
    @dx=random(-2,2)/10.0
    @dy=random(2,5)/10.0
    @lifetime=random(180,255)
  simulate: =>
    @x+=@dx
    @y+=@dy
    @x=width/psize if @x<0
    @x=0     if @x>width/psize
    @lifetime-=1
    if @lifetime<=0
      @initValues!
  color: =>
    255-(@lifetime/2),@lifetime/2,min(255,max(0,4*(@lifetime-150))),@lifetime


particles={}

gl.utInitContextVersion 3, 3
gl.utInitContextFlags gl.UT_DEBUG
gl.utInitContextProfile gl.UT_CORE_PROFILE
gl.utInitDisplayString 'rgba double depth>=16 samples~4'
gl.utInitWindowSize width, height
gl.utInitWindowPosition 100,100

window = gl.utCreateWindow 'Feuer'
gl.utFullScreen!

gl.ClearColor 0, 0, .1, 1
gl.Enable gl.BLEND
gl.BlendFunc gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA

particleProgram = gl.program{
  [gl.VERTEX_SHADER]:   gl.path 'shaders.particle', 'vert'
  [gl.FRAGMENT_SHADER]: gl.path 'shaders.particle', 'frag'
}

vbdata={
  -1, -1
   1, -1
  -1,  1
   1,  1
}

sizeof={
  float: ffi.sizeof 'GLfloat'
  ubyte: ffi.sizeof 'GLubyte'
}

glFloatv=ffi.typeof 'GLfloat[?]'
glUBytev=ffi.typeof 'GLubyte[?]'

vao = gl.GenVertexArray!
gl.BindVertexArray vao

vbptr=glFloatv #vbdata, vbdata
pposptr=glFloatv max_particles*3
pcolptr=glUBytev max_particles*4

vb=gl.GenBuffer!
gl.BindBuffer gl.ARRAY_BUFFER, vb
gl.BufferData gl.ARRAY_BUFFER, sizeof.float*#vbdata, vbptr, gl.STATIC_DRAW

pb=gl.GenBuffer!
gl.BindBuffer gl.ARRAY_BUFFER, pb
gl.BufferData gl.ARRAY_BUFFER, sizeof.float*max_particles*3, ffi.NULL, gl.STREAM_DRAW

cb=gl.GenBuffer!
gl.BindBuffer gl.ARRAY_BUFFER, cb
gl.BufferData gl.ARRAY_BUFFER, sizeof.ubyte*max_particles*4, ffi.NULL, gl.STREAM_DRAW

gl.utDisplayFunc ->
  gl.BindVertexArray vao

  gl.BindBuffer gl.ARRAY_BUFFER, pb
  gl.BufferData gl.ARRAY_BUFFER, sizeof.float*max_particles*3, ffi.NULL, gl.STREAM_DRAW
  gl.BufferSubData gl.ARRAY_BUFFER, 0, sizeof.float*#particles*3, pposptr

  gl.BindBuffer gl.ARRAY_BUFFER, cb
  gl.BufferData gl.ARRAY_BUFFER, sizeof.ubyte*max_particles*4, ffi.NULL, gl.STREAM_DRAW
  gl.BufferSubData gl.ARRAY_BUFFER, 0, sizeof.ubyte*#particles*4, pcolptr

  gl.Clear bit.bor gl.COLOR_BUFFER_BIT, gl.DEPTH_BUFFER_BIT

  particleProgram!

  gl.EnableVertexAttribArray 0
  gl.BindBuffer gl.ARRAY_BUFFER, vb
  gl.VertexAttribPointer 0, 2, gl.FLOAT, gl.FALSE, 0, ffi.NULL
  gl.VertexAttribDivisor 0, 0

  gl.EnableVertexAttribArray 1
  gl.BindBuffer gl.ARRAY_BUFFER, pb
  gl.VertexAttribPointer 1, 3, gl.FLOAT, gl.FALSE, 0, ffi.NULL
  gl.VertexAttribDivisor 1, 1

  gl.EnableVertexAttribArray 2
  gl.BindBuffer gl.ARRAY_BUFFER, cb
  gl.VertexAttribPointer 2, 4, gl.UNSIGNED_BYTE, gl.TRUE, 0, ffi.NULL
  gl.VertexAttribDivisor 2, 1

  gl.DrawArraysInstanced gl.TRIANGLE_STRIP, 0, 4, #particles

  gl.utSwapBuffers!
  err=gl.GetError!
  if 0~=err
    print "GlErrors:"
  while 0~=err
    print "  "..err
    err=gl.GetError!

gl.utReshapeFunc (w,h)->
  width=w
  height=h
  particleProgram!
  particleProgram.modelViewProjectionMatrix = gl.ortho(0, width/psize, 0, height/psize, -20, 20)
  gl.Viewport 0, 0, w, h

gl.utIdleFunc ->
  p\simulate! for p in *particles
  for i=1,#particles
    p=particles[i]
    pposptr[i*3]  =p.x
    pposptr[i*3+1]=p.y
    pposptr[i*3+2]=0
    pcolptr[i*4], pcolptr[i*4+1], pcolptr[i*4+2], pcolptr[i*4+3] = p\color!
  table.insert particles,Particle! for i=1, min(50, max_particles-#particles)
  gl.utPostRedisplay!

gl.utMainLoop!
