all:
	ldc src/boomstick.d -I../tango -I/home/wolfwood/repos/ldc/runtime/import -I/home/wolfwood/repos/ldc/runtime/internal  -L-ltango -L-L../tango

haskell: test/xomb.canon.dot test/xomb.canon.png test/xomb.png

test/xomb.canon.png: test/xomb.canon.dot
	dot -o $@ $<

test/xomb.png: test/xomb.dot
	dot -o $@ $<

test/xomb.canon.dot: test/xomb.dot src/test
	./src/test < test/xomb.dot > test/xomb.canon.dot

src/test: src/test.hs
	ghc --make src/test.hs
