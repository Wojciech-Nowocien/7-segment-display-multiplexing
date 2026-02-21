@rem If it doesn't work use different port (not COM7) instead
avrdude -c avr109 -p atmega32u4 -P COM7 -b 57600 -D -U flash:w:program.hex:i