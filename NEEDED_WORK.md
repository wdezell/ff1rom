# Needed Work



##### ATOBS:  ASCII Numerical String to Signed 16-bit Binary Conversion
**Given:**  
An integer numeric value represented as an ASCII strz with HL pointing to MSD, 
convert to an equivalent 16-bit 2's Complement signed binary value stored in the
memory word pointed to by DE.

The following modifiers will be supported:
* The number will be assumed to be base-10 decimal if only the digits 0-9 are present plus an optional preceding minus sign '-'
* The number will be interpreted as base-16 hexadecimal if the characters A-F appear or if $ or H appear as a prefix or suffix
* The number will be interpreted as base-2 binary if 'b' or 'B' appear as a prefix or suffix
* The number will be interpreted as base-8 octal if 'o' or 'O' appear as a prefix or suffix
* The value will be interpreted as negative if '-' appears as a prefix or suffix

A return with Carry Flag = 1 will signify a conversion error and invalid result.
The following conditions will trigger such an error:
* A number whose conversion exceeds the range of +32768 to -32767
* The appearance of any character invalid for the radix and not being one of the supported modifiers.
This includes the decimal point '.'

---
##### ATOBU:  ASCII Numerical String to Unsigned 16-bit Binary Conversion
**Given:**  
As above, with the following differences:
* The '-' is not permitted and will trigger a conversion error
* Permissible value range is 0 to 65535
* Value is stored as a 16-bit binary value

---
##### BTOAS:  16-bit Signed Binary to ASCII Numerical String Conversion
**Given:**

**HL**:  Pointer to 16-bit 2's Complement signed binary value

**DE:**  Pointer to output conversion buffer

**B:**  Size of conversion buffer

**A:**  Format specifier code.  One of:
* ' '  (space) - Display as base-10 decimal number
* b - Display as base-2 Binary number
* h - Display as base-16 Hexadecimal number
* o - Display as base-8 Octal number
---
##### BTOAU: 16-bit Unsigned Binary to ASCI Numerical String Conversion
