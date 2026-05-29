build:
	odin build . -debug

build-wayland: build

run: build
	./vulkan-odin

run-wayland: build-wayland
	GLFW_PLATFORM=wayland ./vulkan-odin
