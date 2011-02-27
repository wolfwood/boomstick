all:
	ldc src/boomstick.d -I../tango -I/home/wolfwood/repos/ldc/runtime/import -I/home/wolfwood/repos/ldc/runtime/internal  -L-ltango -L-L../tango
