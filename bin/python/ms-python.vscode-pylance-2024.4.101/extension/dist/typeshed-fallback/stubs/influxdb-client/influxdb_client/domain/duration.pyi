from _typeshed import Incomplete

class Duration:
    openapi_types: Incomplete
    attribute_map: Incomplete
    discriminator: Incomplete
    def __init__(
        self, type: Incomplete | None = None, magnitude: Incomplete | None = None, unit: Incomplete | None = None
    ) -> None: ...
    @property
    def type(self): ...
    @type.setter
    def type(self, type) -> None: ...
    @property
    def magnitude(self): ...
    @magnitude.setter
    def magnitude(self, magnitude) -> None: ...
    @property
    def unit(self): ...
    @unit.setter
    def unit(self, unit) -> None: ...
    def to_dict(self): ...
    def to_str(self): ...
    def __eq__(self, other): ...
    def __ne__(self, other): ...
