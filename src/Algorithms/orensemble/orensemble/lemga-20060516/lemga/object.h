// -*- C++ -*-
#ifndef __COMMON_TYPES_OBJECT_H__
#define __COMMON_TYPES_OBJECT_H__

/** @file
 *  @brief Object class, _register_creator, and other common types.
 *
 *  $Id: object.h 2554 2006-01-18 02:55:21Z ling $
 */

#ifdef size_t
typedef size_t UINT;
#else
typedef unsigned long UINT;
#endif

typedef double REAL;

#define INFINITESIMAL   (8e-16) ///< almost equal to 0, 1+x/2-1>0
#define EPSILON         (1e-9)  ///< accumulated numerical error
#undef  INFINITY
/// Should avoid using INFINITY since it is a lazy trick.
#define INFINITY        (5e30)

#ifdef __cplusplus

#include <stdio.h>
#include <iostream>
#include <string>
#include <vector>

/** @brief Stop the program and warn when an undefined function is called.
 *
 *  Some member functions may be @em optional for child classes. There
 *  are two cases for an optional function:
 *   -# It is declared as an interface; Some child classes may implement
 *      it but others may not. This macro should be called in the interface
 *      class. See NNLayer::train for an example.
 *   -# It is defined and implemented but may be inappropriate for some
 *      child classes. To prevent misuse of this function, use this macro
 *      to redefine it in those child classes.
 *
 *  This macro will stop the program with a ``function undefined" error.
 *
 *  @note This approach differs from defining functions as pure virtual,
 *  since using the latter way, a child class cannot be instantiated without
 *  implementing all pure virtual functions, while some of them may not
 *  be desired.
 *
 *  @todo A better macro name; Auto-extraction of function name (could be
 *  done by __PRETTY_FUNCTION__ but is not compatible between compilers)
 */
#define OBJ_FUNC_UNDEFINED(fun)    \
    std::cerr<<__FILE__":"<<__LINE__<<": "<<id()<<"::" fun " undefined.\n"; \
    exit(-99);

/** @brief The root (ancestor) of all classes.
 *
 *  Object class collects some very common and useful features. It has
 *  a static string for identification and several funtional interfaces.
 */
class Object {
    friend std::istream& operator>> (std::istream&, Object&);
    friend std::ostream& operator<< (std::ostream&, const Object&);

public:
    virtual ~Object ()  {}

    typedef std::string id_t;
    /** @return Class ID string (class name) */
    virtual const id_t& id () const = 0;

    /** @brief Create a new object using the default constructor.
     *
     *  The code for a derived class Derived is always
     *  @code return new Derived(); @endcode
     */
    virtual Object* create () const = 0;

    /// Create a new object from an input stream.
    static Object* create (std::istream&);

    /** @brief Create a new object by replicating itself.
     *  @return A pointer to the new copy.
     *
     *  The code for a derived class Derived is always
     *  @code return new Derived(*this); @endcode
     *  Though seemingly redundant, it helps to copy an object without
     *  knowing the real type of the object.
     *  @sa C++ FAQ Lite 20.6
     */
    virtual Object* clone () const = 0;

protected:
    static const id_t NIL_ID;
    typedef UINT ver_t;
    typedef std::vector<ver_t> ver_list;
    /** @brief Serialize the object to an output stream.
     *  @sa Macro SERIALIZE_PARENT, unserialize()
     *
     *  Each class should either have its own serialize() and a positive
     *  version number, or ensure that all its descendants don't overload
     *  serialize() thus have 0 as the version number. This way we can
     *  safely assume, if we go down in the object hierarchy tree from
     *  Object to the any class, the versions are positive numbers followed
     *  by 0's. In other words, the version list is preceded by some 0's.
     */
    virtual bool serialize (std::ostream&, ver_list&) const;
    /** @brief Unserialize from an input stream.
     *  @sa Macro UNSERIALIZE_PARENT, serialize()
     *
     *  The ID and version list are used for sanity check. For any parent
     *  classes, the ID will be set to @a NIL_ID. Thus any classes that
     *  is definitely some parent should assert ID == @a NIL_ID.
     *
     *  A class which previously did not have its own serialize() or
     *  unserialize(), usually because it had nothing to store, can have
     *  its own serialize() and unserialize() later on, as long as it takes
     *  care of the 0 version number case in unserialize().
     */
    virtual bool unserialize (std::istream&, ver_list&, const id_t& = NIL_ID)
    { return true; }
};

inline std::ostream& operator<< (std::ostream& os, const Object& obj) {
    Object::ver_list vl_empty;
    obj.serialize(os, vl_empty);
    return os;
}

typedef Object* (*_creator_t) ();

/** Unserialization from an input stream will create an object of a now
 *  unknown class. To facilitate this process, each instantiable derived
 *  class (that is, a class with all pure virtual functions implemented)
 *  must have a creator and add it to this map. The way is to declare a
 *  static _register_creator object in the .cpp file.
 *  @code static const _register_creator _("Derived", _creator); @endcode
 *  @sa C++ FAQ Lite 35.8
 */
struct _register_creator {
    _register_creator(const Object::id_t&, _creator_t);
};

/// Use a prefix @a p to allow several classes in a same .cpp file
#define REGISTER_CREATOR2(cls,p)                             \
    static const Object::id_t p##_id_ = #cls;                \
    static Object* p##_c_ () { return new cls; }             \
    const Object::id_t& cls::id () const { return p##_id_; } \
    static const _register_creator p##_(p##_id_, p##_c_)
#define REGISTER_CREATOR(cls) REGISTER_CREATOR2(cls,)

/** @brief Serialize parents (ancestors) part.
 *  @param pcls Parent class.
 *  @param os Output stream.
 *  @param def_ver Current (default) version.
 */
#define SERIALIZE_PARENT(pcls,os,vl,def_ver) \
    vl.push_back(def_ver); pcls::serialize(os, vl)

/** @brief Unserialize parents and set current format number @a ver.
 *  @param pcls Parent class (input).
 *  @param is Input stream (input).
 *  @param ver Version number for this class (output).
 */
#define UNSERIALIZE_PARENT(pcls,is,vl,def_ver,ver) \
    if (!pcls::unserialize(is, vl)) return false; \
    const ver_t ver = vl.back(); \
    if (ver > def_ver) { \
        std::cerr << this->id() \
                  << ": unserialize: format newer than the program\n"; \
        return false; \
    } \
    if (ver > 0) vl.pop_back()

#endif // __cplusplus

#ifdef  __OBJECT_H__
#warning "This header file may conflict with another `object.h' file."
#endif
#define __OBJECT_H__
#endif
