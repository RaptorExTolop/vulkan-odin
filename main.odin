package main

import app "src/application"

main :: proc() {
	application := app.newApplication(800, 600, "Hello Vulkan")
	app.runApplication(&application)
}


