VERSION=$(strip $(shell cat version))
RELEASE_VERSION=v$(VERSION)
GIT_VERSION=$(strip $(shell git rev-parse --short HEAD))

version-bump:
	@git tag -a $(RELEASE_VERSION) -m "Release $(RELEASE_VERSION). Revision is: $(GIT_VERSION)"
	@git push origin $(RELEASE_VERSION)

