package main

import "core:fmt"
import glm "core:math/linalg/glsl"

Camera :: struct {
    position: glm.vec3,
    forward: glm.vec3,
    right: glm.vec3,
    up: glm.vec3,
    world_up: glm.vec3,
    is_locked: bool,
    near: f32,
    far: f32,
    fov: f32,
    projection: glm.mat4,
    view: glm.mat4
}

camera_new :: proc(camera: ^Camera) {
    camera.forward = {0, 0, -1}
    camera.world_up = {0, 1, 0}
    camera.is_locked = true
    camera.near = 0.001
    camera.far = 1000
    camera.fov = glm.radians_f32(90)
    camera_rotate(camera, 0, 0, 0)
}

camera_move :: proc(camera: ^Camera, direction: glm.vec3) {
    camera.position += camera.forward * direction.z
    camera.position += camera.right * direction.x
    camera.position += camera.up * direction.y
}

camera_rotate :: proc(camera: ^Camera, yaw: f32, pitch: f32, roll: f32) {
    if (camera.is_locked) {
        camera.up = camera.world_up
    }

    // yaw
    quat := glm.quatAxisAngle(camera.up, -yaw)
    camera.forward = glm.normalize(glm.quatMulVec3(quat, camera.forward))
    camera.right = glm.normalize(glm.cross(camera.forward, camera.up))

    // pitch
    quat = glm.quatAxisAngle(camera.right, -pitch)
    forward := glm.normalize(glm.quatMulVec3(quat, camera.forward))

    if !camera.is_locked || abs(glm.dot(forward, camera.up)) < 0.99 {
        camera.forward = forward
    }

    // roll
    if (!camera.is_locked && roll != 0) {
        quat = glm.quatAxisAngle(camera.forward, -roll)
        camera.right = glm.normalize(glm.quatMulVec3(quat, camera.right))
    }

    camera.up = glm.normalize(glm.cross(camera.right, camera.forward))
}

camera_point_at :: proc(camera: ^Camera, point: glm.vec3) {
    if glm.distance(camera.position, point) < glm.F32_EPSILON {
        return
    }

    if (camera.is_locked) {
        camera.up = camera.world_up
    }

    camera.forward = glm.normalize(point - camera.position)
    camera.right = glm.normalize(glm.cross(camera.forward, camera.up))
    camera.up = glm.normalize(glm.cross(camera.right, camera.forward))
}

camera_compute_projection :: proc(camera: ^Camera, viewport_x: f32, viewport_y: f32) {
    camera.projection = glm.mat4Perspective(camera.fov, viewport_x / viewport_y, camera.near, camera.far)
}

camera_compute_view :: proc(camera: ^Camera) {
    camera.view = glm.mat4LookAt(camera.position, camera.position + camera.forward, camera.up)
}

camera_lock :: proc(camera: ^Camera) {
    camera.is_locked = true
    camera.world_up = camera.up
}

camera_unlock :: proc(camera: ^Camera) {
    camera.is_locked = false
}
