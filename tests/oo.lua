package.path = "../src/?.lua;"..(package.path or "")
require "oo"


for _,type in pairs{"tab", "lol"} do
    oo.default(type)
    
    testo = oo.object:intend{
        a=1,
        b=5,
        geta = oo.public (function(self)
            return self.a
        end),
        getb = (function (self)
            return self.b
        end),
        hit = oo.public (function(self, amount)
            self.a = self.a + amount
        end)}
    testp = testo:intend{
        c = 7,
        getc = oo.public (function (self)
            return self.c
        end),
        sum = oo.public (function (self)
            return self.c + self.b + self.a
        end),
        hit = oo.public (function (self, amount)
            self.c = self.c + amount
        end),
        new = oo.public (function (self, aval)
            return self:intend{
                a = aval
            }
        end)
    }
    testq = testp:new(77)
    print(testo:geta())
    
    testo:hit(7)
    testp:hit(2)
    
    print(testo:geta())
    print(testp:geta())
    print(testp:getc())
    print(testp:sum())

    print(testq:geta())

    print()
end