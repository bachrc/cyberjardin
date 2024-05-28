[private]
default:
  just --choose

# Hot reloads a local dev server
dev:
  npx quartz build --serve

# Synchronizes the blog with Github, auto deploying it
sync:
  npx quartz sync
