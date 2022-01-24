---
layout: post
title:  "Enabling Doxygen comments in Visual Studio"
author: "Rob Zimmerman"
image: doxygen_header.png
excerpt_separator: <!--more-->
---

# _Comment All The Things!_

Comments are good. At least that's my default disposition. Although they don't take the place of proper end-user documentation, or architecture documentation, they serve as a helpful guide to future code spelunkers. 
<!--more-->

In the past, I've always used a 3rd party plugin or tool (something like [Visual Assist](https://www.wholetomato.com/)) for quick and easy function header comment templates. With the latest version of Visual Studio 2019, those days are gone. 

## Default Comment Blocks
By default, if you type three forward slashes (`///`), an XML Doc comment will be spawned:

Example:
```cpp
/// <summary>
/// 
/// </summary>
/// <param name="pJob"></param>
/// <param name="pParent"></param>
void Fiber::Activate(Job* pJob, Fiber* pParent) {

    // The thread that we'll switch back to when the job is complete
```

Here's an example of that key combination in action:

![]({{ "/assets/images/blog/vs_function_header_example.gif" | relative_url }})

That's fine and all, but I'm more of a [Doxygen](https://www.doxygen.nl/index.html) kind of guy. Thankfully, there's an option for that now!

## Enabling Doxygen
Navigate to `Tools -> Options -> Text Edtitor -> C/C++ -> Code Style -> General`. 

---
***NOTE:*** If `Code Style` isn't available in the `C/C++` section, you need to upgrade your version of Visual Studio. 

---

From there' you'll be provided with a drop down showing the following options

![]({{ "/assets/images/blog/vs_doxygen_menu.png" | relative_url }})

Each Doxygen option will allow you to use a different key sequence to start a header. In turn, each different key sequence will also generate a slightly different format of the header. 

### `///`
Replaces the standard XML Doc key sequence with a simple single line comment version of the function docstring.
```cpp
/// @brief 
/// @param pJob 
/// @param pParent 
void Fiber::Activate(Job* pJob, Fiber* pParent) {

    // The thread that we'll switch back to when the job is complete
    m_pParent = pParent;
```

### `/**`
Multi-line version of the Doxygen function header docstring.
```cpp
/**
 * @brief 
 * @param pJob 
 * @param pParent 
*/
void Fiber::Activate(Job* pJob, Fiber* pParent) {

    // The thread that we'll switch back to when the job is complete
    m_pParent = pParent;
```

### `/*!`
Slight variation on the multiline comment docstring.
```cpp
/*!
 * @brief 
 * @param pJob 
 * @param pParent 
*/
void Fiber::Activate(Job* pJob, Fiber* pParent) {

    // The thread that we'll switch back to when the job is complete
    m_pParent = pParent;
```

### `//!`
Another version of the single line docstring template.
```cpp
//! @brief 
//! @param pJob 
//! @param pParent 
void Fiber::Activate(Job* pJob, Fiber* pParent) {

    // The thread that we'll switch back to when the job is complete
    m_pParent = pParent;

```
---

And that's it! Go forth...and sprinkle well commented function and method headers throughout your codebase!

<p align="center">
<img src='{{"/assets/images/blog/docstring_all_the_things.png" | relative_url }}'/>
</p>