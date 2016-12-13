package.path = "?.lua;?/init.lua;" .. package.path
local max_particles = 20000
local width = 800
local height = 600
local psize = 10
local ffi = require('ffi')
local gl = require('glua')
local random, min, max
do
  local _obj_0 = require('math')
  random, min, max = _obj_0.random, _obj_0.min, _obj_0.max
end
local Particle
do
  local _class_0
  local _base_0 = {
    initValues = function(self)
      self.x = random(0, width / psize)
      self.y = 0
      self.dx = random(-2, 2) / 10.0
      self.dy = random(2, 5) / 10.0
      self.lifetime = random(180, 255)
    end,
    simulate = function(self)
      self.x = self.x + self.dx
      self.y = self.y + self.dy
      if self.x < 0 then
        self.x = width / psize
      end
      if self.x > width / psize then
        self.x = 0
      end
      self.lifetime = self.lifetime - 1
      if self.lifetime <= 0 then
        return self:initValues()
      end
    end,
    color = function(self)
      return 255 - (self.lifetime / 2), self.lifetime / 2, min(255, max(0, 4 * (self.lifetime - 150))), self.lifetime
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      return self:initValues()
    end,
    __base = _base_0,
    __name = "Particle"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Particle = _class_0
end
local particles = { }
gl.utInitContextVersion(3, 3)
gl.utInitContextFlags(gl.UT_DEBUG)
gl.utInitContextProfile(gl.UT_CORE_PROFILE)
gl.utInitDisplayString('rgba double depth>=16 samples~4')
gl.utInitWindowSize(width, height)
gl.utInitWindowPosition(100, 100)
local window = gl.utCreateWindow('Feuer')
gl.utFullScreen()
gl.ClearColor(0, 0, .1, 1)
gl.Enable(gl.BLEND)
gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
local particleProgram = gl.program({
  [gl.VERTEX_SHADER] = gl.path('shaders.particle', 'vert'),
  [gl.FRAGMENT_SHADER] = gl.path('shaders.particle', 'frag')
})
local vbdata = {
  -1,
  -1,
  1,
  -1,
  -1,
  1,
  1,
  1
}
local sizeof = {
  float = ffi.sizeof('GLfloat'),
  ubyte = ffi.sizeof('GLubyte')
}
local glFloatv = ffi.typeof('GLfloat[?]')
local glUBytev = ffi.typeof('GLubyte[?]')
local vao = gl.GenVertexArray()
gl.BindVertexArray(vao)
local vbptr = glFloatv(#vbdata, vbdata)
local pposptr = glFloatv(max_particles * 3)
local pcolptr = glUBytev(max_particles * 4)
local vb = gl.GenBuffer()
gl.BindBuffer(gl.ARRAY_BUFFER, vb)
gl.BufferData(gl.ARRAY_BUFFER, sizeof.float * #vbdata, vbptr, gl.STATIC_DRAW)
local pb = gl.GenBuffer()
gl.BindBuffer(gl.ARRAY_BUFFER, pb)
gl.BufferData(gl.ARRAY_BUFFER, sizeof.float * max_particles * 3, ffi.NULL, gl.STREAM_DRAW)
local cb = gl.GenBuffer()
gl.BindBuffer(gl.ARRAY_BUFFER, cb)
gl.BufferData(gl.ARRAY_BUFFER, sizeof.ubyte * max_particles * 4, ffi.NULL, gl.STREAM_DRAW)
gl.utDisplayFunc(function()
  gl.BindVertexArray(vao)
  gl.BindBuffer(gl.ARRAY_BUFFER, pb)
  gl.BufferData(gl.ARRAY_BUFFER, sizeof.float * max_particles * 3, ffi.NULL, gl.STREAM_DRAW)
  gl.BufferSubData(gl.ARRAY_BUFFER, 0, sizeof.float * #particles * 3, pposptr)
  gl.BindBuffer(gl.ARRAY_BUFFER, cb)
  gl.BufferData(gl.ARRAY_BUFFER, sizeof.ubyte * max_particles * 4, ffi.NULL, gl.STREAM_DRAW)
  gl.BufferSubData(gl.ARRAY_BUFFER, 0, sizeof.ubyte * #particles * 4, pcolptr)
  gl.Clear(bit.bor(gl.COLOR_BUFFER_BIT, gl.DEPTH_BUFFER_BIT))
  particleProgram()
  gl.EnableVertexAttribArray(0)
  gl.BindBuffer(gl.ARRAY_BUFFER, vb)
  gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 0, ffi.NULL)
  gl.VertexAttribDivisor(0, 0)
  gl.EnableVertexAttribArray(1)
  gl.BindBuffer(gl.ARRAY_BUFFER, pb)
  gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 0, ffi.NULL)
  gl.VertexAttribDivisor(1, 1)
  gl.EnableVertexAttribArray(2)
  gl.BindBuffer(gl.ARRAY_BUFFER, cb)
  gl.VertexAttribPointer(2, 4, gl.UNSIGNED_BYTE, gl.TRUE, 0, ffi.NULL)
  gl.VertexAttribDivisor(2, 1)
  gl.DrawArraysInstanced(gl.TRIANGLE_STRIP, 0, 4, #particles)
  gl.utSwapBuffers()
  local err = gl.GetError()
  if 0 ~= err then
    print("GlErrors:")
  end
  while 0 ~= err do
    print("  " .. err)
    err = gl.GetError()
  end
end)
gl.utReshapeFunc(function(w, h)
  width = w
  height = h
  particleProgram()
  particleProgram.modelViewProjectionMatrix = gl.ortho(0, width / psize, 0, height / psize, -20, 20)
  return gl.Viewport(0, 0, w, h)
end)
gl.utIdleFunc(function()
  for _index_0 = 1, #particles do
    local p = particles[_index_0]
    p:simulate()
  end
  for i = 1, #particles do
    local p = particles[i]
    pposptr[i * 3] = p.x
    pposptr[i * 3 + 1] = p.y
    pposptr[i * 3 + 2] = 0
    pcolptr[i * 4], pcolptr[i * 4 + 1], pcolptr[i * 4 + 2], pcolptr[i * 4 + 3] = p:color()
  end
  for i = 1, min(50, max_particles - #particles) do
    table.insert(particles, Particle())
  end
  return gl.utPostRedisplay()
end)
return gl.utMainLoop()
