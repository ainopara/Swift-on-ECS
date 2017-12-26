# Swift on ECS - Yet Another Entity-Component-System Framework in Swift

__This framework is not even in prototype stage, most infrastructures are not yet implemented. This README is more a manifesto than an introduction.__

## Overview
[comment]: # (Shall add an overview to smallest use cases of the framework when the project is roughly done.)

## What Is Swift on ECS

Swift on ECS (You can pronouce it as "Swift on X", though the industry
often pronouce ECS as three separated alphabets, but I think its too
verbose.) is yet another Entity-Component-System framework written in
Swift.

### Basic Understanding to Entity-Component-System

Entity-Component-System is not an original concept born with Swift on ECS,
and yet not new. It firstly have been used in commercial software
development in 1998, and the most recent successful application, I think,
is Overwatch by Blizzard Entertainment. The concept of Entity-Component-
System can be seen as another kind of taxonomy opposite to the think of
Object-Oriented Design. It focuses on the concept of "has-a", and merely
involves the concept of "is-a". Such a characteristic takes the advantage
of composition over inheritance and could dramatically reduce the
complexity of code (not the complexity of computation).

A typical Entity-Component-System framework contains following three
things:

- **Entity**: An **identifier** managed by the framework, which represents a collection of components.
- **Component**: A dedicated **storage** of data fields, which has no behaviors.
- **System**: A **sub procedure** executed over time, which has no states.

And since the word "system" here is a dedicated terminology in the Entity-
Component-System world, typically we call the "system" contains these
three things a "world", "context" or, in Swift on ECS, "manager".

```graph
                       +--------+
                     +--------+ |
                   +--------+ | +
               +---| System | +
               |   +--------+
               |
+---------+    |
| Manager |<---+
+---------+    |       +--------+
               |     +--------+ |
               |   +--------+ | +
               +---| Entity | +
                   +----|---+
                        |
                        |      +------------+
                        |    +------------+ |
                        |   +-----------+ | +
                        +---| Component | +
                            +-----------+
```

Conceptually, we can have a slice of components on an entity, or say,
a "tuple". With the knowledge of Set Theory, we can know that:

- A "tuple" is a subset of components on an entity.
- A "tuple" can be an entity itself.
- A "tuple" can be nothing because it could be an empty set.

Systems focuses on tuples. When the manager dispatches systems over time,
it also gives each system a context to keep touch with tuples which each
system concerns about.

The core concepts here is:

- Components have no behaviors.
- Systems have no states.
- Entities gain polymorphism by adding and removing components.

Now, let's make a concrete understand about the reason why this kind of
architecture reduces the complexity of code by examples.

#### Begining of the Example

Consider there are three entities which represent three buttons on a
mobile device's user interface and contains following components:

- `WiewHierarchy`: Stores the view hierarchy of the button entity.
- `Geometry`: Stores the button entity's bounds and center.
- `Touchability`: Stores the button entity's touch-ability
- `DrawingContext`: Stores the drawing context of the button entity.
- `DescriptionTexts`: Stores the the button entity's description texts which are displayed on the screen.
- `TouchUpInsideAction`: Stores the action after the button entity got tapped.

All these entities works with `Layout` system, `Render` system and
`GestureRecognition` system, and those systems do things as their names
tell. You might think: where is the root view? Trust me, it doesn't matter
in following examples.

```graph
On User Interface:

+---------+ +---------+ +---------+
| Button1 | | Button2 | | Button3 |
+---------+ +---------+ +---------+

--------------------------------------------------------------------------

Entity-Component:
+---------------------+ +---------------------+ +---------------------+
| Entity 1            | | Entity 2            | | Entity 3            |
+---------------------+ +---------------------+ +---------------------+
| WiewHierarchy       | | WiewHierarchy       | | WiewHierarchy       |
|                     | |                     | |                     |
| Geometry            | | Geometry            | | Geometry            |
|                     | |                     | |                     |
| Touchability        | | Touchability        | | Touchability        |
|                     | |                     | |                     |
| DrawingContext      | | DrawingContext      | | DrawingContext      |
|                     | |                     | |                     |
| DescriptionTexts    | | DescriptionTexts    | | DescriptionTexts    |
|                     | |                     | |                     |
| TouchUpInsideAction | | TouchUpInsideAction | | TouchUpInsideAction |
+---------------------+ +---------------------+ +---------------------+

System:
+--------+    +--------+
| Layout | -> | Render |
+--------+    +--------+

+--------------------+
| GestureRecognition |
+--------------------+
```

#### Simple Example

One day, your designer told you that it wants all these three buttons can
be affected by gravity, which means each button can be rotated slightly
about each button's center when users swings its device.

```graph
                                      |
+---------+ +---------+ +---------+   |
| Button1 | | Button2 | | Button3 |   | Gravity
+---------+ +---------+ +---------+   |
                                      ⌄
```

This is not difficult in Object-Oriented world. Adding relative
properties, adding button instances to a managing context which is driven
by gravity solves the problem. But I want to show you how the same problem
get solved in ECS world.

We can add a `Gravity` component to each entity, and add a `GravityLayout`
system after the `Layout` system and before the `Render` system -- such a
system can "fix" the layout result done by `Layout` system, and things
done.

```graph
Entity-Component:
+---------------------+ +---------------------+ +---------------------+
| Entity 1            | | Entity 2            | | Entity 3            |
+---------------------+ +---------------------+ +---------------------+
| WiewHierarchy       | | WiewHierarchy       | | WiewHierarchy       |
|                     | |                     | |                     |
| Geometry            | | Geometry            | | Geometry            |
|                     | |                     | |                     |
| Touchability        | | Touchability        | | Touchability        |
|                     | |                     | |                     |
| DrawingContext      | | DrawingContext      | | DrawingContext      |
|                     | |                     | |                     |
| DescriptionTexts    | | DescriptionTexts    | | DescriptionTexts    |
|                     | |                     | |                     |
| TouchUpInsideAction | | TouchUpInsideAction | | TouchUpInsideAction |
|                     | |                     | |                     |
| * Gravity           | | * Gravity           | | * Gravity           |
+---------------------+ +---------------------+ +---------------------+

System:
+--------+    +-----------------+    +--------+
| Layout | -> | * GravityLayout | -> | Render |
+--------+    +-----------------+    +--------+

+--------------------+
| GestureRecognition |
+--------------------+
```

#### More Difficult Example

Since this example is too simple to tell how dramatically the code
complexity reduced by the concept, we can get a more difficult problem:

One day, your designer told you that it no longer wants all these three
buttons can be affected by gravity, but wants all of them can be
conditionally transitioned between button and slider.

```graph
               +---------+ +---------+ +---------+
               | Button1 | | Button2 | | Button3 |
               +---------+ +---------+ +---------+


                                ^
                                |
                                | Transition, under specific condition.
                                |
                                ˅

               +---------+ +---------+ +---------+
               | Slider1 | | Slider2 | | Slider3 |
               +---------+ +---------+ +---------+
```

Since we know that `UIButton` and `UISlider` are two different subclasses
which both are inherited from `UIControl`, you have firstly to have a
wrapper `UIView` instance and then manages a `UIControl` and `UIButton`
instance with the wrapper `UIView` instance to make your "button" had such
a polymorphism.

```graph
      +-----------+
      | UIControl |
      +-----------+
            ^
            |
      +-----+-----+
      |           |
+----------+ +----------+
| UIButton | | UISlider |
+----------+ +----------+
```

But in ECS world, we can introduce a system named
`ButtonToSliderTransition` to the manager. This system focuses on
listening to the signal of "button-to-slider" and "slider-to-button"
transition,

```graph
Entity-Component:
+---------------------+ +---------------------+ +---------------------+
| Entity 1            | | Entity 2            | | Entity 3            |
+---------------------+ +---------------------+ +---------------------+
| WiewHierarchy       | | WiewHierarchy       | | WiewHierarchy       |
|                     | |                     | |                     |
| Geometry            | | Geometry            | | Geometry            |
|                     | |                     | |                     |
| Touchability        | | Touchability        | | Touchability        |
|                     | |                     | |                     |
| DrawingContext      | | DrawingContext      | | DrawingContext      |
|                     | |                     | |                     |
| DescriptionTexts    | | DescriptionTexts    | | DescriptionTexts    |
|                     | |                     | |                     |
| TouchUpInsideAction | | TouchUpInsideAction | | TouchUpInsideAction |
+---------------------+ +---------------------+ +---------------------+

System:
+--------+    +--------+
| Layout | -> | Render |
+--------+    +--------+

+--------------------+
| GestureRecognition |
+--------------------+

+----------------------------+
| * ButtonToSliderTransition |
+----------------------------+
```

and do following changes when a button-to-slider transition signal was
received:

- Removing `DescriptionTexts` component from those entities.
- Removing `TouchUpInsideAction` component from those entities.
- Adding `Domain<Double>` component to those entities.
- Adding `Value<Double>` component to those entities.
- Adding `ValueChangeAction` component to those entities.

```graph
Entity-Component:
+---------------------+ +---------------------+ +---------------------+
| Entity 1            | | Entity 2            | | Entity 3            |
+---------------------+ +---------------------+ +---------------------+
| WiewHierarchy       | | WiewHierarchy       | | WiewHierarchy       |
|                     | |                     | |                     |
| Geometry            | | Geometry            | | Geometry            |
|                     | |                     | |                     |
| Touchability        | | Touchability        | | Touchability        |
|                     | |                     | |                     |
| DrawingContext      | | DrawingContext      | | DrawingContext      |
|                     | |                     | |                     |
| * Domain<Double>    | | * Domain<Double>    | | * Domain<Double>    |
|                     | |                     | |                     |
| * Value<Double>     | | * Value<Double>     | | * Value<Double>     |
|                     | |                     | |                     |
| * ValueChangeAction | | * ValueChangeAction | | * ValueChangeAction |
+---------------------+ +---------------------+ +---------------------+

System:
+--------+    +--------+
| Layout | -> | Render |
+--------+    +--------+

+--------------------+
| GestureRecognition |
+--------------------+

+----------------------------+
| * ButtonToSliderTransition |
+----------------------------+
```

do following changes when a slider-to-button transition signal was
received:

- Removing `Domain<Double>` component from those entities.
- Removing `Value<Double>` component from those entities.
- Removing `ValueChangeAction` component from those entities.
- Adding `DescriptionTexts` component to those entities.
- Adding `TouchUpInsideAction` component to those entities.

```graph
Entity-Component:
+---------------------+ +---------------------+ +---------------------+
| Entity 1            | | Entity 2            | | Entity 3            |
+---------------------+ +---------------------+ +---------------------+
| WiewHierarchy       | | WiewHierarchy       | | WiewHierarchy       |
|                     | |                     | |                     |
| Geometry            | | Geometry            | | Geometry            |
|                     | |                     | |                     |
| Touchability        | | Touchability        | | Touchability        |
|                     | |                     | |                     |
| DrawingContext      | | DrawingContext      | | DrawingContext      |
|                     | |                     | |                     |
| DescriptionTexts    | | DescriptionTexts    | | DescriptionTexts    |
|                     | |                     | |                     |
| TouchUpInsideAction | | TouchUpInsideAction | | TouchUpInsideAction |
+---------------------+ +---------------------+ +---------------------+

System:
+--------+    +--------+
| Layout | -> | Render |
+--------+    +--------+

+--------------------+
| GestureRecognition |
+--------------------+

+----------------------------+
| * ButtonToSliderTransition |
+----------------------------+
```

Since the `Render` system renders entities with a slice of components
contains `Domain` `Value` and `ValueChangeAction` as a slider, and a slice
contains `DescriptionTexts` and `TouchUpInsideAction` as a button, those
entities would be transitioned into a slider when the
`ButtonToSliderTransition` system received a "button-to-slider" transition
signal, and a button when received a "slider-to-button" transition signal.

**And all we done is just introducing a new system to the ECS world.**

### Specialization for Swift Makes Swift on ECS

Recall the figure of elements in a typical ECS architecture.

```graph
                       +--------+
                     +--------+ |
                   +--------+ | +
               +---| System | +
               |   +--------+
               |
+---------+    |
| Manager |<---+
+---------+    |       +--------+
               |     +--------+ |
               |   +--------+ | +
               +---| Entity | +
                   +----|---+
                        |
                        |      +------------+
                        |    +------------+ |
                        |   +-----------+ | +
                        +---| Component | +
                            +-----------+
```

The figure is quite simple. But there might be tons of issues if the
architecture is implemented naïvely, such as:

- Storing components contiguously in a local container owned by an entity and storing entities in an array might improve locality, but dramatically reduces the performance of re-allocation.
- Since systems iterate slices of components over time, the performance would be bad if components to be iterated doesn't enjoy a good locality.
- Since systems iterate slices of components over time, the performance would be bad if systems cannot filter wnated components efficiently -- escpecially for systems only concers about a few numbers of slices of components but there are tons of entities.
- Systems can be dispatched concurrently by resolving their dependencies into a directed acyclic graph, but you might miss this optimization point in your implementation.
- Component slice can be recognized with a bit-string, but such a data structure is not shipped with the standard library, you might also miss the optimization point in your implementation.

...

But generally speaking, most of the issues are about performance. Or
strictlly speaking, can be solved by Data-Oriented Design.

#### Data-Oriented Design

##### Locality of Single Component Iteration

Conceptually, we can improve locality of single component iteration with
an old pattern -- pooling. But pooling is quite difficult in Swift --
because the allocation phase of a `class` instance is "under the hood" --
which cannot be interfered by developers. We can only use `struct` to
express components in Swift. Stack allocation caused by such a value
semantic might beat retain-release overhead if the `struct` is super big.
The solution to this issue is waiting for the implementation of the
`shared` keyword in Swift Ownership Manifesto.

```graph
+-----------------------------------------------------+
| Component Pool                                      |
|                                                     |
| +-------------+ +-------------+ +-------------+     |
| | A Component | | A Component | | A Component | ... |
| +-------------+ +-------------+ +-------------+     |
+-----------------------------------------------------+
```

##### Locality of Component Slice Iteration

But with the solution to improve locality of single component iteration,
performance of iterating over "tuples", or say, slices of components is
still bad. A system might only concerns a few numbers of slices of
components but still have to iterate over all the entities. This can be
solved by introducing a kind of system -- reactive system: which is
dispatched by observing adding/updating/removing about a kind of component
slice, or say, "group". We can cache changed tuples and dispatch reactive
systems iterating over those cached tuples. And such a reactive system
actually can be empowered by implementing a set of Reactive Extension API.

##### Locality of Iteration in System Dispatching

Systems are stored in a "manager", such a manager book-keeps a directed
acyclic graph for the dependency of systems to help with concurrently
system dispatch. To implement a graph, neither adjacency matrix nor
adjacency list is required. We actually can store systems in an array, and
represent dependency with the indices in the array. And dispatching
systems just means iteraing over the array.

#### Dispatching Systems

Systems are dispatched in two ways: an implicit way or reactive way. The
implicit way can still be split into driven by command frame and by user
event.

##### Command Frame System

Command frame is driven by the display's refresh rate on Apple platform,
which is designed for rendering and reading user inputs.

##### User Frame System

User event if driven by the operating system's event loop, which is the
main thread's run loop on Apple platform. This is designed for preemptive
multi processs operating system, which mostly have an event loop
mechanism.

##### Reactive System

The reactive ways are driven by changes done on components.

## What does Swift on ECS do

You might ask: How the entities get managed? How the components get
accessed? How the components get stored? Or, how the systems get oranized
and dispatched?

These questions are tightly coupled with the characteristics of the Swift
programming language, and all about the implementation detail. It could be
helpful if you can review the concept of ECS architecture and some
implementation details about the Swift programming language.

## The Concept in Depth

Modern software engineering practice prefers composition over inheritance.
The concept of Entity-Component-System is a kind of solution to such a big
idea. But wait! You might remembered that, at WWDC 2014, Apple introduced
Swift as a Protocol-Oriented programming language, which is also a
solution to the same big idea.

But we can easily know that the ECS architecture offers another level of
compositability with a different API granularity than Swift.

### Memory Level

There is a public secret that the core utility of Protocol-Oriented
programming in Swift -- type extension could not have any instance stored
properties. Of course, this is not an issue with the help of Objective-C
runtime, but at least, this kind of convention about composition over
inheritance is not able to amend the shipped memory model "on-the-fly".

[comment]: # (Shall explain Swift object memory model with details here.)

With the ECS architecture, since all things to offer the polymorphism are
dynamic -- done by adding and removing components to and from entities,
you shall never concern about the "stored properties" issue. Such an
ability also shows that ECS architecture offers a smaller granularity
about memory than what in Swift.

### Sub-procedure Level

In Swift, a type extension can have behaviors, and most of the time, is
extended for adding behaviors. Since components in ECS architecture have
no behaviors, and sub-procedures in ECS architecture are just systems --
which have no states, ECS actually offers a larger granularity about sub-
procedures than what in Swift, and this kind of sub-procedure focuses
observing and applying changes on components over time. Since such a sub-
procedure dispatches over time, we actually can implement a set of
Reactive Extension API to relief the pain of building a time elapsing
sensitive sub-procedure.

We can imply that such a larger granularity of sub-procedure can have a
better maintainability than Swift's type extension with the application of
traditional "Actor Pattern", which increases software's maintainability by
splitting resiponsibilities of an "actor" but often get developers stuck
on figuring out how many actors shall be there in a sub-project(I don't
use the word "subsytem" here because "system" is a terminology in ECS
world).

## The Implementation in Depth

## License

The MIT License

Copyright 2017 WeZZard

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
