package.path = "?.lua;?/init.lua;" .. package.path

max_particles=50000

width=800
height=600
psize=8

ffi = require 'ffi'
gl  = require 'glua'
import plane from require 'glua.primitive'
import random,min,max from require'math'

clamp = (x,mi,ma)-> min ma, max mi, x

class Particle
  new: =>
    @initValues!
  initValues: =>
    @x=random(0,width/psize)
    @y=0
    @dx=random(-2,2)/10.0
    @dy=random(2,5)/10.0
    @lifetime=random(160,255)
  simulate: =>
    @x+=@dx
    @y+=@dy
    @x=width/psize if @x<0
    @x=0     if @x>width/psize
    @lifetime-=1
    if (@lifetime % 2) == 0
      @dx+=random(-20,20)/100.0
      @dy+=random(20,50)/100.0
      @dx=clamp(@dx,-.2,.2)
      @dy=clamp(@dy,.2,.5)
    if @lifetime<=0
      @initValues!


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
gl.Disable gl.CULL_FACE
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

glUIntv=ffi.typeof 'GLuint[?]'
glFloatv=ffi.typeof 'GLfloat[?]'
glUBytev=ffi.typeof 'GLubyte[?]'

vao = gl.GenVertexArray!
gl.BindVertexArray vao

vbptr=glFloatv #vbdata, vbdata
pposptr=glFloatv max_particles*3
plftptr=glUBytev max_particles*4

vb=gl.GenBuffer!
gl.BindBuffer gl.ARRAY_BUFFER, vb
gl.BufferData gl.ARRAY_BUFFER, sizeof.float*#vbdata, vbptr, gl.STATIC_DRAW

pb=gl.GenBuffer!
gl.BindBuffer gl.ARRAY_BUFFER, pb
gl.BufferData gl.ARRAY_BUFFER, sizeof.float*max_particles*3, ffi.NULL, gl.STREAM_DRAW

lb=gl.GenBuffer!
gl.BindBuffer gl.ARRAY_BUFFER, lb
gl.BufferData gl.ARRAY_BUFFER, sizeof.ubyte*max_particles, ffi.NULL, gl.STREAM_DRAW


fbv=glUIntv 1
gl.GenFramebuffers 1, fbv
fb=fbv[0]

fbt=gl.GenTexture!
gl.BindTexture gl.TEXTURE_2D, fbt
gl.TexImage2D gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, ffi.NULL
gl.TexParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR
gl.TexParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR
gl.BindFramebuffer gl.FRAMEBUFFER, fb
gl.FramebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fbt, 0

blurProgram = gl.program{
  [gl.VERTEX_SHADER]:   gl.path 'shaders.blur', 'vert'
  [gl.FRAGMENT_SHADER]: gl.path 'shaders.blur', 'frag'
}

blurPlane=plane blurProgram

gl.utDisplayFunc ->
  gl.BindFramebuffer gl.FRAMEBUFFER, fb

  gl.ActiveTexture gl.TEXTURE0
  gl.BindTexture gl.TEXTURE_2D, 0

  gl.BindVertexArray vao

  gl.BindBuffer gl.ARRAY_BUFFER, pb
  gl.BufferData gl.ARRAY_BUFFER, sizeof.float*max_particles*3, ffi.NULL, gl.STREAM_DRAW
  gl.BufferSubData gl.ARRAY_BUFFER, 0, sizeof.float*#particles*3, pposptr

  gl.BindBuffer gl.ARRAY_BUFFER, lb
  gl.BufferData gl.ARRAY_BUFFER, sizeof.ubyte*max_particles, ffi.NULL, gl.STREAM_DRAW
  gl.BufferSubData gl.ARRAY_BUFFER, 0, sizeof.ubyte*#particles, plftptr

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
  gl.BindBuffer gl.ARRAY_BUFFER, lb
  gl.VertexAttribPointer 2, 1, gl.UNSIGNED_BYTE, gl.TRUE, 0, ffi.NULL
  gl.VertexAttribDivisor 2, 1

  gl.DrawArraysInstanced gl.TRIANGLE_STRIP, 0, 4, #particles

  gl.BindFramebuffer gl.FRAMEBUFFER, 0
  gl.Clear bit.bor gl.COLOR_BUFFER_BIT, gl.DEPTH_BUFFER_BIT

  gl.ActiveTexture gl.TEXTURE0
  gl.BindTexture gl.TEXTURE_2D, fbt

  blurPlane!

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
  gl.BindTexture gl.TEXTURE_2D, fbt
  gl.TexImage2D gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, ffi.NULL
  gl.TexParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR
  gl.TexParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR
  gl.BindFramebuffer gl.FRAMEBUFFER, fb
  gl.FramebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fbt, 0
  particleProgram!
  particleProgram.modelViewProjectionMatrix = gl.ortho(0, w/psize, 0, h/psize, -20, 20)
  blurProgram!
  blurProgram.modelViewProjectionMatrix = gl.ortho(-1, 1, -1, 1, -20, 20)
  gl.Viewport 0, 0, w, h

gl.utIdleFunc ->
  for i=1,#particles
    p=particles[i]
    p\simulate!
    pposptr[i*3]  =p.x
    pposptr[i*3+1]=p.y
    pposptr[i*3+2]=0
    plftptr[i]    = p.lifetime
  if #particles < max_particles
    table.insert particles,Particle! for i=1, min(100, max_particles-#particles)
  gl.utPostRedisplay!

gl.utMainLoop!
