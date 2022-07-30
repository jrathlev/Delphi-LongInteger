### Delphi Long-integer arithmetic

The unit **XMathUtils.pas** provides routines for calculations of positive 
(unsigned) integer values of any length. Variables, declared as such 
extra-long integers, can be used with common operators (e.g. +, -, * and /) in 
the source code \(see 
[Embarcadero documentation](http://docwiki.embarcadero.com/RADStudio/Tokyo/en/Operator_Overloading_(Delphi))\). 

Beyond that the following functions are supported:

- Checks for zero, even and odd values
- Conversions from and to decimal and to hex strings
- Functions similar to DivMod and MulDiv
- Functions to compute power and square root
- Functions to compute factorials and binomials

In addition to the unit, the package contains a demo program and a program 
for computing any number of digits of Pi using the algorithm according 
to [P. Borwein](http://www.cecm.sfu.ca/personal/pborwein).
