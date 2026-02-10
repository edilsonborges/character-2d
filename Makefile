GAME_NAME = character2d
SRC_FILES = main.lua conf.lua

.PHONY: all run love web clean

# Run locally with Love2D
run:
	love .

# Package as .love file (used by all platforms)
$(GAME_NAME).love: $(SRC_FILES)
	zip -9 $(GAME_NAME).love $(SRC_FILES)

love: $(GAME_NAME).love

# Web build using love.js (requires npx love.js)
web: $(GAME_NAME).love
	@mkdir -p build/web
	npx love.js $(GAME_NAME).love build/web --title "Character 2D" --memory 67108864
	@echo "Web build ready in build/web/ — serve with: npx serve build/web"

clean:
	rm -rf build/ $(GAME_NAME).love
