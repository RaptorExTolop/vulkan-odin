package hellotriangle

import "core:fmt"
import "vendor:glfw"
import vk "vendor:vulkan"
import "core:log"

helloTriangleApplication :: struct {
	width, height: i32,
	title: cstring,
	window: glfw.WindowHandle,
	vulkanInstance: vk.Instance,
	validationLayers : []cstring, 
	validationLayersEnabled: bool,
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
	// glfw.InitHint(glfw.PLATFORM, glfw.PLATFORM_WAYLAND)
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
	
	// create the vulkan application info to create a Vulkan Instance
	appInfo := vk.ApplicationInfo{
		sType = .APPLICATION_INFO,
		pApplicationName = "Hello Vulkan",
		applicationVersion = vk.MAKE_VERSION(0, 1, 1),
		pEngineName = "No Engine",
		engineVersion = vk.MAKE_VERSION(1, 0, 0),
		apiVersion = vk.API_VERSION_1_4,
	}

	a.validationLayers = {"VK_LAYER_KHRONOS_validation"}

	when ODIN_DEBUG {
		a.validationLayersEnabled = true
	} else {
		a.validationLayersEnabled = false
	}

	// if we are checking for validation layers get the validation layers
	requiredLayers: []cstring = a.validationLayersEnabled ? a.validationLayers : {}

	supportedLayersCount: u32
	vk.EnumerateInstanceLayerProperties(&supportedLayersCount, nil)
	supportedLayers := make([]vk.LayerProperties, supportedLayersCount)
	defer delete(supportedLayers)
	vk.EnumerateInstanceLayerProperties(&supportedLayersCount, raw_data(supportedLayers))

	fmt.printfln("Req Layers: {}", requiredLayers)
	for required in requiredLayers {
		found := false 
		for &layer in supportedLayers {
			if cstring(&layer.layerName[0]) == required {
				found = true
				break
			}
		}
		if (!found) {
			log.fatalf("Required layer not supported: {}\n", required)
		}
	}

	extensions := getRequiredInstanceExtensions(a)
	defer delete(extensions)

	createInfo := vk.InstanceCreateInfo{
		sType = .INSTANCE_CREATE_INFO,
		pApplicationInfo = &appInfo,
		enabledExtensionCount = u32(len(extensions)),
		ppEnabledExtensionNames = raw_data(extensions),
		enabledLayerCount = u32(len(requiredLayers)),
		ppEnabledLayerNames = raw_data(requiredLayers),
	}

	result := vk.CreateInstance(&createInfo, nil, &a.vulkanInstance)
	if result != .SUCCESS {
		log.fatalf("Failed to create VK instance: {}", result)
	}

	// load the glfw instance proc address and pass it into vulkan
	vk.load_proc_addresses_global(cast(rawptr)glfw.GetInstanceProcAddress)
}

@private
getRequiredInstanceExtensions :: proc(a: ^helloTriangleApplication) -> [dynamic]cstring {
	glfwExtentionCount: u32 = 0
	glfwExtentions := glfw.GetRequiredInstanceExtensions()
	glfwExtentionCount = u32(len(glfwExtentions))
	extensions := make([dynamic]cstring, glfwExtentionCount)
	copy(extensions[:], glfwExtentions)

	if (a.validationLayersEnabled) {
		append(&extensions, vk.EXT_DEBUG_UTILS_EXTENSION_NAME)
	}

	// num of supported extensions
	supportedCount: u32
	// check if the required GLFW extensions are supported by the Vulkan implementation
	vk.EnumerateInstanceExtensionProperties(nil, &supportedCount, nil)
	// make an array of the supported extensions
	supportedExtensions := make([]vk.ExtensionProperties, supportedCount)
	// make sure to delete the data
	defer delete(supportedExtensions)
	// get the extension properties and put all of them into an array 
	vk.EnumerateInstanceExtensionProperties(nil, &supportedCount, raw_data(supportedExtensions))

	// for each glfw extension
	for i in 0..<glfwExtentionCount {
		required := glfwExtentions[i]
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

	return extensions
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
	vk.DestroyInstance(a.vulkanInstance, nil)

	glfw.DestroyWindow(a.window)
	glfw.Terminate()
}

