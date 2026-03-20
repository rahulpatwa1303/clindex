.PHONY: up down logs restart apk

## Start backend + web dashboard (builds images if needed)
up:
	docker compose up -d --build
	@echo ""
	@echo "  Backend  → http://localhost:8000"
	@echo "  Web      → http://localhost:3000"
	@echo ""

## Stop all services
down:
	docker compose down

## Tail logs from all services (Ctrl+C to exit)
logs:
	docker compose logs -f

## Restart all services
restart: down up

## Build a release APK pointed at your backend + Supabase
##   Usage: make apk IP=192.168.1.x SUPABASE_URL=https://... SUPABASE_ANON_KEY=eyJ...
##   Or with a tunnel: make apk IP=192.168.1.x SUPABASE_URL=https://abc.ngrok-free.app SUPABASE_ANON_KEY=eyJ...
apk:
	@if [ -z "$(IP)" ]; then \
		echo ""; \
		echo "  ERROR: IP is required."; \
		echo "  Usage: make apk IP=<your-machine-local-ip> SUPABASE_URL=<url> SUPABASE_ANON_KEY=<key>"; \
		echo ""; \
		echo "  Find your IP with: ip route get 1 | awk '{print \$$7; exit}'"; \
		echo ""; \
		exit 1; \
	fi
	@if [ -z "$(SUPABASE_URL)" ]; then \
		echo ""; \
		echo "  ERROR: SUPABASE_URL is required."; \
		echo "  Usage: make apk IP=$(IP) SUPABASE_URL=<url> SUPABASE_ANON_KEY=<key>"; \
		echo ""; \
		exit 1; \
	fi
	@if [ -z "$(SUPABASE_ANON_KEY)" ]; then \
		echo ""; \
		echo "  ERROR: SUPABASE_ANON_KEY is required."; \
		echo "  Usage: make apk IP=$(IP) SUPABASE_URL=$(SUPABASE_URL) SUPABASE_ANON_KEY=<key>"; \
		echo ""; \
		exit 1; \
	fi
	cd apps/mobile && flutter build apk \
		--dart-define=API_URL=http://$(IP):8000 \
		--dart-define=SUPABASE_URL=$(SUPABASE_URL) \
		--dart-define=SUPABASE_ANON_KEY=$(SUPABASE_ANON_KEY)
	@echo ""
	@echo "  APK ready: apps/mobile/build/app/outputs/flutter-apk/app-release.apk"
	@echo "  Install:   adb install apps/mobile/build/app/outputs/flutter-apk/app-release.apk"
	@echo ""
