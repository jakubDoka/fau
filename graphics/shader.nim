import ../gl, tables, options

type ShaderAttr* = object
    name*: string
    gltype*: GLenum
    size*: GLint
    length*: Glsizei
    location*: GLint

type Shader* = ref object
    handle, vertHandle, fragHandle: GLuint
    compileLog: string
    compiled: bool
    uniforms: Table[string, int]
    attributes: Table[string, ShaderAttr]

proc loadSource(shader: Shader, shaderType: GLenum, source: string): GLuint =
    result = glCreateShader(shaderType)
    if result == 0: return 0.GLuint

    #attach source
    glShaderSource(result, source)
    glCompileShader(result)

    #check compiled status
    let compiled = glGetShaderiv(result, GL_COMPILE_STATUS)

    if compiled == 0:
        shader.compiled = false
        shader.compileLog &= ("[" & (if shaderType == GL_FRAGMENT_SHADER: "fragment shader" else: "vertex shader") & "]\n")
        let infoLen = glGetShaderiv(result, GL_INFO_LOG_LENGTH)
        if infoLen > 1:
            let infoLog = glGetShaderInfoLog(result)
            shader.compileLog &= infoLog #append reason to log
        glDeleteShader(result)

proc dispose*(shader: Shader) = 
    glUseProgram(0)
    glDeleteShader(shader.vertHandle)
    glDeleteShader(shader.fragHandle)
    glDeleteProgram(shader.handle)

proc use*(shader: Shader) =
    glUseProgram(shader.handle)

proc newShader*(vertexSource, fragmentSource: string): Shader =
    result = Shader()
    result.uniforms = initTable[string, int]()
    result.compiled = true
    result.vertHandle = loadSource(result, GL_VERTEX_SHADER, vertexSource)
    result.fragHandle = loadSource(result, GL_FRAGMENT_SHADER, fragmentSource)

    if not result.compiled:
        raise Exception.newException("Failed to compile shader: \n" & result.compileLog)

    var program = glCreateProgram()
    glAttachShader(program, result.vertHandle)
    glAttachShader(program, result.fragHandle)
    glLinkProgram(program)

    let status = glGetProgramiv(program, GL_LINK_STATUS)

    if status == 0:
        let infoLen = glGetProgramiv(program, GL_INFO_LOG_LENGTH)
        if infoLen > 1:
            let infoLog = glGetProgramInfoLog(program)
            result.compileLog &= infoLog #append reason to log
            result.compiled = false
        raise Exception.newException("Failed to link shader: " & result.compileLog) 

    result.handle = program

    #fetch attributes for shader
    let numAttrs = glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES)
    for i in 0..<numAttrs:
        var alen: GLsizei
        var asize: GLint
        var atype: GLenum
        var aname: string
        glGetActiveAttrib(program, i.GLuint, alen, asize, atype, aname)
        let aloc = glGetAttribLocation(program, aname)
        result.attributes[aname] = ShaderAttr(name: aname, size: asize, length: alen, gltype: atype, location: aloc)


#attribute functions

proc getAttributeLoc*(shader: Shader, alias: string): int = 
    if not shader.attributes.hasKey(alias): return -1
    return shader.attributes[alias].location

proc getAttribute*(shader: Shader, alias: string): Option[ShaderAttr] = 
    if not shader.attributes.hasKey(alias): return none(ShaderAttr)
    return some(shader.attributes[alias])

proc enableAttribute*(shader: Shader, location: GLuint, size: GLint, gltype: Glenum, normalize: GLboolean, stride: GLsizei, offset: int) = 
    glEnableVertexAttribArray(location)
    glVertexAttribPointer(location, size, gltype, normalize, stride, cast[pointer](offset));

proc disableAttribute*(shader: Shader, alias: string) = 
    if shader.attributes.hasKey(alias):
        glDisableVertexAttribArray(shader.attributes[alias].location.GLuint)

#uniform setting functions

proc findUniform(shader: Shader, name: string): int =
    if shader.uniforms.hasKey(name):
        return shader.uniforms[name]
    let location = glGetUniformLocation(shader.handle, name)
    shader.uniforms[name] = location
    return location

proc setf(shader: Shader, name: string, value: float) =
    let loc = shader.findUniform(name)
    if loc != -1: glUniform1f(loc.GLint, value.GLfloat)

proc setf(shader: Shader, name: string, value1, value2: float) =
    let loc = shader.findUniform(name)
    if loc != -1: glUniform2f(loc.GLint, value1.GLfloat, value2.GLfloat)

proc setf(shader: Shader, name: string, value1, value2, value3: float) =
    let loc = shader.findUniform(name)
    if loc != -1: glUniform3f(loc.GLint, value1.GLfloat, value2.GLfloat, value3.GLfloat)

proc setf(shader: Shader, name: string, value1, value2, value3, value4: float) =
    let loc = shader.findUniform(name)
    if loc != -1: glUniform4f(loc.GLint, value1.GLfloat, value2.GLfloat, value3.GLfloat, value4.GLfloat)
    