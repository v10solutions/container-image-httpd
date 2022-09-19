#
# Container Image HTTPD
#

.PHONY: pki-build-%
pki-build-%:
	mkdir -p ".output/pki/$(*)"
	$(BIN_DOCKER) buildx build \
		-f "pki.dockerfile" \
		--pull \
		--force-rm \
		--progress "plain" \
		--platform "$(PROJ_PLATFORM_OS)/$(PROJ_PLATFORM_ARCH)" \
		--build-arg PROJ_NAME="$(PROJ_NAME)" \
		--build-arg CFSSL_VERSION="$(CFSSL_VERSION)" \
		--target "$(*)" \
		-o type="local",dest=".output/pki/$(*)" \
		"."

.PHONY: pki-rm-%
pki-rm-%:
	rm -r -f ".output/pki/$(*)"
