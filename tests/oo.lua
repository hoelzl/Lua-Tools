package.path = "../src/?.lua;"..(package.path or "")
require "oo"


for _,type in pairs{"tab", "lol", "noo"} do
    oo.default(type)
    
    testo = oo.object:intend{
        pos = oo.dynamic{x=1, y=1},
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
        end),
        getx = oo.public (function(self)
            return self.pos.x
        end),
        gety = oo.public (function (self)
            return self.pos.y
        end),
        move = oo.public (function(self)
            self.pos.x = self.pos.x + 1
            self.pos.y = self.pos.y + 1
        end)
    }
    testp = testo:intend{
        c = 7,
        t = oo.dynamic(testo),
        getc = oo.public (function (self)
            return self.c
        end),
        sum = oo.public (function (self)
            return self.c + self.b + self.a
        end),
        hit = oo.public (function (self, amount)
            self.c = self.c + amount
        end),
        gett = oo.public (function (self)
            return self.t
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

    print(testo:getx(), testo:gety())
    print(testp:getx(), testp:gety())
    testo:move()
    print(testo:getx(), testo:gety())
    print(testp:getx(), testp:gety())
    testp:move()
    print(testo:getx(), testo:gety())
    print(testp:getx(), testp:gety())
    
    print(testq:gett():geta(), testo:geta())
    
    print()
end