package hellotriangle

import "vendor:glfw"
import vk "vendor:vulkan"
import "core:log"

helloTriangleApplication :: struct {
	width, height: i32,
	title: cstring,
	window: glfw.WindowHandle,
	vulkanInstance: vk.Instance,
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
	createInstance(a)
}

@private
createInstance :: proc(a: ^helloTriangleApplication) {
	// load the glfw instance proc address and pass it into vulkan
	vk.load_proc_addresses_global(cast(rawptr)glfw.GetInstanceProcAddress)

	// create the vulkan application info to create a Vulkan Instance
	appInfo := vk.ApplicationInfo{
		sType = .APPLICATION_INFO,
		pApplicationName = "Hello Vulkan",
		applicationVersion = vk.MAKE_VERSION(0, 1, 1),
		pEngineName = "No Engine",
		engineVersion = vk.MAKE_VERSION(1, 0, 0),
		apiVersion = vk.API_VERSION_1_4,
	}

	// get the extensions and the extension count
	glfwExtensions := glfw.GetRequiredInstanceExtensions()
	glfwExtensionCount := u32(len(glfwExtensions))

	// num of supported extensions
	supportedCount: u32
	// check if the required GLFW extensions are supported by the Vulkan implementation
	vk.EnumerateInstanceExtensionProperties(nil, &supportedCount, nil)
	// make an array of the supported extensions
	supportedExtensions := make([]vk.ExtensionProperties, supportedCount)
	// make sure to delete the data
	defer delete(supportedExtensions)
	// 
	vk.EnumerateInstanceExtensionProperties(nil, &supportedCount, raw_data(supportedExtensions))

	for i in 0..<glfwExtensionCount {
		required := glfwExtensions[i]
		found := false

		for &ext in supportedExtensions {
			if string(cstring(&ext.extensionName[0])) == string(required) {
				found = true
				break
			}
		}

		if (!found) {
			log.fatalf("Required GLFW extension not supported: {}\n", required)
		}
	}

	createInfo := vk.InstanceCreateInfo{
		sType = .INSTANCE_CREATE_INFO,
		pApplicationInfo = &appInfo,
		enabledExtensionCount = glfwExtensionCount,
		ppEnabledExtensionNames = raw_data(glfwExtensions),
	}

	result := vk.CreateInstance(&createInfo, nil, &a.vulkanInstance)
	if result != .SUCCESS {
		log.fatalf("Failed to create VK instance: {}", result)
	}
	// defer vk.DestroyInstance(a.vulkanInstance, nil)
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

