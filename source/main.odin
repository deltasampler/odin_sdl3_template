package main

import "core:fmt"
import sdl "vendor:sdl3"
import gl "vendor:OpenGL"

WINDOW_TITLE :: "Odin SDL3 Template"
WINDOW_WIDTH :: 960
WINDOW_HEIGHT :: 540
GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 6

VERTEX_SOURCE :: `#version 460 core
    out vec2 v_tex_coord;

    const vec2 positions[4] = vec2[](
        vec2(-1.0, -1.0),
        vec2(1.0, -1.0),
        vec2(-1.0, 1.0),
        vec2(1.0, 1.0)
    );

    const vec2 tex_coords[4] = vec2[](
        vec2(0.0, 0.0),
        vec2(1.0, 0.0),
        vec2(0.0, 1.0),
        vec2(1.0, 1.0)
    );

    void main() {
        gl_Position = vec4(positions[gl_VertexID], 0.0, 1.0);
        v_tex_coord = tex_coords[gl_VertexID];
    }
`

FRAGMENT_SOURCE :: `#version 460 core
    precision mediump float;
    in vec2 v_tex_coord;
    out vec4 o_frag_color;

    void main() {
        o_frag_color = vec4(v_tex_coord, 0.0, 1.0);
    }
`

main :: proc() {
    if !sdl.Init({.VIDEO}) {
        fmt.printf("SDL ERROR: %s\n", sdl.GetError())

        return
    }

    defer sdl.Quit()

    window := sdl.CreateWindow(WINDOW_TITLE, WINDOW_WIDTH, WINDOW_HEIGHT, {.OPENGL})
    defer sdl.DestroyWindow(window)

    sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GLProfile.CORE))
    sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
    sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

    gl_context := sdl.GL_CreateContext(window)
    defer sdl.GL_DestroyContext(gl_context)

    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, sdl.gl_set_proc_address)

    program, program_status := gl.load_shaders_source(VERTEX_SOURCE, FRAGMENT_SOURCE)

    if !program_status {
        fmt.printf("SHADER LOAD ERROR: %s\n", gl.get_last_error_message())

        return
    }

    defer gl.DeleteProgram(program)

    vao: u32; gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao)
    gl.BindVertexArray(vao)

    loop: for {
        event: sdl.Event

        for sdl.PollEvent(&event) {
            #partial switch event.type {
                case .QUIT:
                    break loop
            }
        }

        gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
        gl.ClearColor(0.5, 0.5, 0.5, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)
        gl.UseProgram(program)
        gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4)

        sdl.GL_SwapWindow(window)
    }
}
