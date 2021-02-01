import scene as s

s.MAX_BOUNCES = 10

s.Material("simple", (0.2, 0, 0.2), 1, 0.4, 0, 0.7, 0.0, 1.0)
s.Material("floor", (0.6, 0.6, 0.6), 0, 1, 0.2, 0, 0.0, 1.0)

s.Object("ball0", "sphere", (0, 1, 0), 1, "simple")
s.Object("ball1", "sphere", (2, 1.5, 0), 1, "simple")
s.Object("ball2", "sphere", (-2, 0, 0), 1, "simple")
s.Object("ball3", "sphere", (0, 1.5, 2), 1, "simple")
s.Object("ball4", "sphere", (0, 0, -2), 1, "simple")
s.Object("ball5", "sphere", (2, 2, 2), 1, "simple")
s.Object("ball6", "sphere", (-2, -0.5, -2), 1, "simple")

s.Object("floor", "plane", (0, -2, 0), 1, "floor")

s.Camera((-2, 3, -7), (0, 1.5, 0))

s.Light((0, 10, 10), (10, 10, 10))
s.Light((0, 10, -10), (10, 10, 10))

s.generate("basic")