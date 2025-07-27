package main

import "core:fmt"
import glm "core:math/linalg/glsl"

CAMERA_WORLD_UP : glm.vec3 : {0, 1, 0}

Camera :: struct {
    position: glm.vec3,
    forward: glm.vec3,
    right: glm.vec3,
    up: glm.vec3,
    projection: glm.mat4,
    view: glm.mat4,
    near: f32,
    far: f32,
    fov: f32,
    movement_speed: f32,
    yaw_speed: f32,
    pitch_speed: f32,
}

camera_new :: proc(camera: ^Camera) {
    camera.forward = {0, 0, -1}
    camera.right = {1, 0, 0}
    camera.up = {0, 1, 0}
    camera.near = 0.01
    camera.far = 1000
    camera.fov = glm.radians_f32(90)
    camera.movement_speed = 4
    camera.yaw_speed = 0.002
    camera.pitch_speed = 0.002
}

camera_move :: proc(camera: ^Camera, direction: glm.vec3) {
    camera.position += camera.forward * direction.z * camera.movement_speed
    camera.position += camera.right * direction.x * camera.movement_speed
    camera.position += camera.up * direction.y * camera.movement_speed
}

camera_rotate :: proc(camera: ^Camera, yaw: f32, pitch: f32) {
    quat := glm.quatAxisAngle(CAMERA_WORLD_UP, -yaw * camera.yaw_speed)
    camera.forward = glm.normalize(glm.quatMulVec3(quat, camera.forward))

    quat = glm.quatAxisAngle(camera.right, -pitch * camera.pitch_speed)
    forward := glm.normalize(glm.quatMulVec3(quat, camera.forward))

    if abs(glm.dot(forward, CAMERA_WORLD_UP)) < 0.99 {
        camera.forward = forward
    }

    camera.right = glm.normalize(glm.cross(camera.forward, CAMERA_WORLD_UP))
    camera.up = glm.normalize(glm.cross(camera.right, camera.forward))
}

camera_point_at :: proc(camera: ^Camera, point: glm.vec3) {
    camera.forward = glm.normalize(point - camera.position)
    camera.right = glm.normalize(glm.cross(camera.forward, CAMERA_WORLD_UP))
    camera.up = glm.normalize(glm.cross(camera.right, camera.forward))
}

camera_compute_projection :: proc(camera: ^Camera, viewport_x: f32, viewport_y: f32) {
    camera.projection = glm.mat4Perspective(camera.fov, viewport_x / viewport_y, camera.near, camera.far)
}

camera_compute_view :: proc(camera: ^Camera) {
    camera.view = glm.mat4LookAt(camera.position, camera.position + camera.forward, camera.up)
}
