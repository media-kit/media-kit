all: Resources/*.dylib

IINA_VERSION=v1.3.1
IINA_SHA256SUM=c646642a2884cb0516922170e0f6d4990b12b41d6244b08d53f318dbb9518c2f

.cache:
	mkdir .cache

.cache/IINA.${IINA_VERSION}.dmg: .cache
	rm -f .cache/*.tmp .cache/*.dmg
	curl -L \
		https://github.com/iina/iina/releases/download/${IINA_VERSION}/IINA.${IINA_VERSION}.dmg \
		-o .cache/IINA.dmg.tmp
	shasum -a 256 -c <<< '${IINA_SHA256SUM}  .cache/IINA.dmg.tmp'
	mv .cache/IINA.dmg.tmp .cache/IINA.${IINA_VERSION}.dmg
	touch .cache/IINA.${IINA_VERSION}.dmg

.cache/IINA.dmg: .cache/IINA.${IINA_VERSION}.dmg
	rm -f .cache/IINA.dmg
	ln -s IINA.${IINA_VERSION}.dmg .cache/IINA.dmg

Resources/*.dylib: .cache/IINA.dmg
	rm -f ./Resources/*.dylib

	hdiutil attach .cache/IINA.dmg
	find /Volumes/IINA/IINA.app/Contents/Frameworks \
		-name '*.dylib' ! -name 'libswift*' \
		-exec cp {} ./Resources/ \;
	hdiutil detach /Volumes/IINA

	mv Resources/libmpv.*.dylib Resources/libmpv.dylib
	install_name_tool \
		-id @rpath/libmpv.dylib \
		Resources/libmpv.dylib \
		2> /dev/null

	./Scripts/relink_dylibs.sh ./Resources
	codesign --remove ./Resources/*.dylib

.PHONY: clean
clean:
	rm -rf .cache
	rm -f ./Resources/*.dylib
