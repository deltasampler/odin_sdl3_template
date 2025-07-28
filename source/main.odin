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
    uniform mat4 u_projection;
    uniform mat4 u_view;

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
        gl_Position = u_projection * u_view * vec4(positions[gl_VertexID], 0.0, 1.0);
        v_tex_coord = tex_coords[gl_VertexID];
    }
`

FRAGMENT_SOURCE :: `#version 460 core
    precision mediump float;
    in vec2 v_tex_coord;
    out vec4 o_frag_color;

    void main() {
        vec2 uv = v_tex_coord * 2.0 - 1.0;

        if (length(uv) > 1.0) {
            discard;
        }

        o_frag_color = vec4(v_tex_coord, 0.0, 1.0);
    }
`

main :: proc() {
    if !sdl.Init({.VIDEO}) {
        fmt.printf("SDL ERROR: %s\n", sdl.GetError())

        return
    }

    defer sdl.Quit()

    window := sdl.CreateWindow(WINDOW_TITLE, WINDOW_WIDTH, WINDOW_HEIGHT, {.OPENGL, .RESIZABLE})
    defer sdl.DestroyWindow(window)

    sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GLProfile.CORE))
    sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
    sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

    gl_context := sdl.GL_CreateContext(window)
    defer sdl.GL_DestroyContext(gl_context)

    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, sdl.gl_set_proc_address)

    sdl.SetWindowPosition(window, sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED)
    _ = sdl.SetWindowRelativeMouseMode(window, true)

    viewport_x, viewport_y: i32; sdl.GetWindowSize(window, &viewport_x, &viewport_y)
    key_state := sdl.GetKeyboardState(nil)
    time: u64 = sdl.GetTicks()
    time_delta : f32 = 0
    time_last := time

    camera: Camera; camera_new(&camera)
    camera.position = {3, 3, 3}
    camera_point_at(&camera, {0, 0, 0})

    program, program_status := gl.load_shaders_source(VERTEX_SOURCE, FRAGMENT_SOURCE)
    uniforms := gl.get_uniforms_from_program(program)

    if !program_status {
        fmt.printf("SHADER LOAD ERROR: %s\n", gl.get_last_error_message())

        return
    }

    defer gl.DeleteProgram(program)

    vao: u32; gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao)
    gl.BindVertexArray(vao)

    loop: for {
        time = sdl.GetTicks()
        time_delta = f32(time - time_last) / 1000
        time_last = time

        event: sdl.Event

        for sdl.PollEvent(&event) {
            #partial switch event.type {
                case .QUIT:
                    break loop
                case .WINDOW_RESIZED:
                    sdl.GetWindowSize(window, &viewport_x, &viewport_y)
                case .KEY_DOWN:
                    if event.key.scancode == sdl.Scancode.ESCAPE {
                        _ = sdl.SetWindowRelativeMouseMode(window, !sdl.GetWindowRelativeMouseMode(window))
                    }
                case .MOUSE_MOTION:
                    if sdl.GetWindowRelativeMouseMode(window) {
                        camera_rotate(&camera, event.motion.xrel, event.motion.yrel)
                    }
            }
        }

        if (sdl.GetWindowRelativeMouseMode(window)) {
            if key_state[sdl.Scancode.A] {
                camera_move(&camera, {-time_delta, 0, 0})
            }

            if key_state[sdl.Scancode.D] {
                camera_move(&camera, {time_delta, 0, 0})
            }

            if key_state[sdl.Scancode.S] {
                camera_move(&camera, {0, 0, -time_delta})
            }

            if key_state[sdl.Scancode.W] {
                camera_move(&camera, {0, 0, time_delta})
            }
        }

        camera_compute_projection(&camera, auto_cast viewport_x, auto_cast viewport_y)
        camera_compute_view(&camera)

        gl.Viewport(0, 0, viewport_x, viewport_y)
        gl.ClearColor(0.5, 0.5, 0.5, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)
        gl.UseProgram(program)
        gl.UniformMatrix4fv(uniforms["u_projection"].location, 1, false, &camera.projection[0][0])
        gl.UniformMatrix4fv(uniforms["u_view"].location, 1, false, &camera.view[0][0])
        gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4)

        sdl.GL_SwapWindow(window)
    }
}
