# Arduino Template

Simple template for Arduino Leonardo projects. If you want to use other board replace [m32U4def.inc](m32U4def.inc) (which 
I edited a little bit, probably commented just one line) with the appropriate file for your device.

## How to use it?

Write your code in [program.asm](program.asm), then, in `WSL` invoke:

```shell
make build
```

Remember to use the command in the right path!

Next, run [upload.bat](upload.bat) in `CMD` or by double click. If it doesn't work replace `COM7` with other port. Use
`Device Manager` to check which correctly. Good luck!