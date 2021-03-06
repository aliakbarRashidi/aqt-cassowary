// Copyright (c) 2014, 2015 Ableton AG, Berlin
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

import QtQuick 2.3
import QtTest 1.0

import Ableton.TestUtils 1.0
import Aqt.Cassowary 1.0

TestScene {
    id: scene

    TestCase {
        id: case1
        property var someVar

        Solver {
            id: s0
            Variable {
                id: v1
            }
            Edit {
                id: e1
                target: v1
                suggested: case1.someVar
            }
            Stay {
                target: v1
            }
        }

        function test_suggestingValues() {
            s0.commit()
            e1.suggest(42)
            s0.commit()
            compare(v1.value, 42)
            e1.suggest(21)
            s0.commit()
            compare(v1.value, 21)
        }

        function test_suggestingValuesThroughBinding() {
            case1.someVar = 42
            e1.commit()
            compare(v1.value, 42)
            case1.someVar = 21
            e1.commit()
            compare(v1.value, 21)
        }
    }

    TestCase {
        Edit { id: e2 }
        function test_defaults() {
            compare(e2.strength, Strength.Strong)
            compare(e2.weight, 1)
        }
    }

    TestCase {
        Solver {
            id: s1
            Variable {
                id: v2
                Edit { suggested: 42 }
            }
        }
        function test_canFindTargetFromParent() {
            s1.commit()
            compare(v2.value, 42)
        }
    }

    TestCase {
        Solver {
            id: s2
            Variable {
                id: v3
                Edit {
                    id: e3
                    when: false
                }
            }
        }

        function test_remembersSuggestiosnUntilEnabled() {
            s2.commit()
            e3.suggested = 42
            s2.commit()
            compare(v3.value, 0)
            e3.suggested = 64
            s2.commit()
            compare(v3.value, 0)

            e3.when = true
            s2.commit()
            compare(v3.value, 64)

            e3.suggested = 42
            e3.when = false
            s2.commit()
            compare(v3.value, 64)
        }
    }

    TestCase {
        Solver {
            id: s3
            Variable {
                id: v4
                Stay {}
                Edit {
                    id: e4
                    when: false
                }
                Constraint {
                    expr: leq(v4, 100)
                }
            }
        }

        function test_variablesCanBeEditedDirectlyRespectingConstraints() {
            v4.value = 42
            s3.commit()
            compare(v4.value, 42)

            v4.value = 142;
            s3.commit()
            compare(v4.value, 100)
        }

        function test_variablesCanBeEditedDirectlyWhileAnEditIsGoingOn() {
            e4.suggested = 21
            e4.when = true
            s3.commit()
            compare(v4.value, 21)

            v4.value = 12
            s3.commit()
            compare(v4.value, 12)

            e4.suggested = 7
            s3.commit()
            compare(v4.value, 7)

            e4.when = false
            v4.value = 5
            e4.suggested = 100
            s3.commit()
            compare(v4.value, 5)
        }
    }

    TestCase {
        Solver {
            id: s5
            Variable {
                id: v5
                Edit {
                    id: e5
                }
                Edit {
                    id: e6
                    strength: Strength.Medium
                }
            }
        }

        function test_editsAreIndependent() {
            e5.suggested = 21
            e6.suggested = 42
            s5.commit()
            compare(v5.value, 21)

            e5.when = false
            s5.commit()
            compare(v5.value, 42)
        }
    }

    TestCase {
        Solver {
            id: s6
            Variable {
                id: v6
                Stay {}
            }
            Variable {
                id: v7
                Stay {}
            }
            Variable {
                id: v8
                Stay {}
            }
            Variable {
                id: v9
                Stay {}
            }
            Constraint {
                expr: eq(100, plus(v6, v7, v8, v9))
            }
        }

        function test_imperativeSuggestOrderingIsRespected() {
            v9.value = 30;
            v8.value = 30;
            v7.value = 30;
            v6.value = 30;
            s6.commit()
            compare(v9.value, 10);

            v7.value = 30;
            v9.value = 30;
            v8.value = 30;
            v6.value = 30;
            s6.commit()
            compare(v7.value, 10);

            v6.value = 30;
            v7.value = 30;
            v9.value = 30;
            v8.value = 30;
            s6.commit()
            compare(v6.value, 10);

            v6.value = 30;
            v7.value = 30;
            v9.value = 30;
            v6.value = 30;
            v8.value = 30;
            v7.value = 30;
            s6.commit()
            compare(v9.value, 10);
        }
    }
}
