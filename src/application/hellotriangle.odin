package hellotriangle

import "vendor:glfw"
import vk "vendor:vulkan"

helloTriangleApplication :: struct {
	width, height: i32,
	title: cstring,
	window: glfw.WindowHandle,
}

newApplication :: proc(width, height: i32, winTitle: cstring) -> helloTriangleApplication {
	return {
		width = width,
		height = height,
		title = winTitle,
	}
}

runApplication :: proc(a: ^helloTriangleApplication) {
	initWindow(a)
	initVulkan(a)
	mainLoop(a)
	cleanUp(a)
}

@private
initWindow :: proc(a: ^helloTriangleApplication) {
	glfw.InitHint(glfw.PLATFORM, glfw.PLATFORM_WAYLAND)
	glfw.Init()

	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	glfw.WindowHint(glfw.RESIZABLE, glfw.FALSE)

	a.window = glfw.CreateWindow(a.width, a.height, a.title, nil, nil)
}

@private
initVulkan :: proc(a: ^helloTriangleApplication) {

}

@private
mainLoop :: proc(a: ^helloTriangleApplication) {
	for (!glfw.WindowShouldClose(a.window)) {
		glfw.PollEvents()
		glfw.SwapBuffers(a.window)
	}
}

@private
cleanUp :: proc(a: ^helloTriangleApplication) {
	glfw.DestroyWindow(a.window)
	glfw.Terminate()
}
