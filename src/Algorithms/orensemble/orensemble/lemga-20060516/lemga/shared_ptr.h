// -*- C++ -*-
#ifndef __CPP_ADDON_SHARED_PTR_H__
#define __CPP_ADDON_SHARED_PTR_H__

/** @file
 *  @brief Shared pointers with reference count.
 *
 *  $Id: shared_ptr.h 1907 2004-12-11 00:51:14Z ling $
 */

/** @warning Do not use this class. Use const_shared_ptr or var_shared_ptr.
 *  @note I guess it is not thread-safe.
 *  @note See boost.org for a better and more complicated implementation.
 */
template <typename T>
class _shared_ptr {
protected:
    T* ptr;
    UINT* pcnt;

    void delete_this () {
        if (valid() && !(--*pcnt)) {
            delete ptr; delete pcnt;
            ptr = 0; pcnt = 0;
        }
    }

    /// @c false if the pointer is null.
    bool valid () const {
        assert((!ptr && !pcnt) || (ptr && pcnt && *pcnt > 0));
        return (ptr != 0);
    }

    UINT use_count () const { assert(valid()); return *pcnt; }
    bool unique () const { return (use_count() == 1); }

public:
    explicit _shared_ptr (T* p = 0) : ptr(p), pcnt(0) {
        if (p) { pcnt = new UINT(1); assert(valid()); } }
    _shared_ptr (const _shared_ptr<T>& s) : ptr(s.ptr), pcnt(s.pcnt) {
        if (valid()) ++(*pcnt); }
    ~_shared_ptr () { delete_this(); }

    const _shared_ptr<T>& operator= (const _shared_ptr<T>& s) {
        if (this == &s) return *this;
        delete_this();
        ptr = s.ptr; pcnt = s.pcnt;
        if (valid()) ++(*pcnt);
        return *this;
    }
    bool operator!= (const T* p) const { return ptr != p; }
    bool operator== (const T* p) const { return ptr == p; }
    bool operator!= (const _shared_ptr& p) const { return ptr != p.ptr; }
    bool operator== (const _shared_ptr& p) const { return ptr == p.ptr; }
    bool operator! () const { return !ptr; }

    typedef bool (_shared_ptr::*implicit_bool_type) () const;
    operator implicit_bool_type () const {
        return ptr? &_shared_ptr::valid : 0;
    }
};

/// Shared pointers (whose content can not be changed).
template <typename T>
class const_shared_ptr : public _shared_ptr<T> {
    using _shared_ptr<T>::valid;
    using _shared_ptr<T>::ptr;
public:
    const_shared_ptr () {}
    const_shared_ptr (T* p) : _shared_ptr<T>(p) {}
    const_shared_ptr (const const_shared_ptr<T>& s) : _shared_ptr<T>(s) {}

    const const_shared_ptr<T>& operator= (const const_shared_ptr<T>& s) {
        _shared_ptr<T>::operator=(s);
        return *this;
    }
    const T* operator-> () const { assert(valid()); return ptr; }
    const T& operator* () const { assert(valid()); return *ptr; }
};

/// Shared pointers (whose content can be changed).
template <typename T>
class var_shared_ptr : public _shared_ptr<T> {
    using _shared_ptr<T>::valid;
    using _shared_ptr<T>::ptr;
public:
    var_shared_ptr () {}
    var_shared_ptr (T* p) : _shared_ptr<T>(p) {}
    var_shared_ptr (const var_shared_ptr<T>& s) : _shared_ptr<T>(s) {}

    const var_shared_ptr<T>& operator= (const var_shared_ptr<T>& s) {
        _shared_ptr<T>::operator=(s);
        return *this;
    }
    T* operator-> () const { assert(valid()); return ptr; }
    T& operator* () const { assert(valid()); return *ptr; }
};

#ifdef  __SHARED_PTR_H__
#warning "This header file may conflict with another `shared_ptr.h' file."
#endif
#define __SHARED_PTR_H__
#endif
