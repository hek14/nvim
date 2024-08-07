from typing import Any
from sympy.core.numbers import Rational
from sympy.polys.domains.groundtypes import _GMPYRational, GMPYRational
from sympy.polys.domains.rationalfield import RationalField
from sympy.utilities import public

class GMPYRationalField(RationalField):
    dtype = GMPYRational
    zero = dtype(0)
    one = dtype(1)
    tp = type(one)
    alias = ...
    def __init__(self) -> None:
        ...
    
    def get_ring(self) -> Any:
        ...
    
    def to_sympy(self, a) -> Rational:
        ...
    
    def from_sympy(self, a) -> _GMPYRational:
        ...
    
    def from_ZZ_python(K1, a, K0) -> _GMPYRational:
        ...
    
    def from_QQ_python(K1, a, K0) -> _GMPYRational:
        ...
    
    def from_ZZ_gmpy(K1, a, K0) -> _GMPYRational:
        ...
    
    def from_QQ_gmpy(K1, a, K0):
        ...
    
    def from_GaussianRationalField(K1, a, K0) -> _GMPYRational | None:
        ...
    
    def from_RealField(K1, a, K0) -> _GMPYRational:
        ...
    
    def exquo(self, a, b):
        ...
    
    def quo(self, a, b):
        ...
    
    def rem(self, a, b) -> dtype:
        ...
    
    def div(self, a, b) -> tuple[Any, dtype]:
        ...
    
    def numer(self, a):
        ...
    
    def denom(self, a):
        ...
    
    def factorial(self, a) -> _GMPYRational:
        ...
    


