/** @file
 *  $Id: object.cpp 2554 2006-01-18 02:55:21Z ling $
 */

#include <assert.h>
#include <map>
#include <sstream>
#include "object.h"

const Object::id_t Object::NIL_ID;

typedef std::map<Object::id_t, _creator_t> _creator_map_t;

/** @brief Wrapper for the static creator map.
 *
 *  The wrapper is to ensure @a cmap is initialized before it is used.
 *  @see C++ FAQ Lite 10.11, 10.12, and 10.13
 */
static _creator_map_t& _creator_map () {
    static _creator_map_t cmap;
    return cmap;
}

/** @return @c true if @id is already registered. */
inline static bool _creator_registered (const Object::id_t& id) {
    return _creator_map().find(id) != _creator_map().end();
}

/** @brief Register @a id with creator @a cf.
 *  @param id String of class identification.
 *  @param cf Function pointer to the creator.
 */
_register_creator::_register_creator (const Object::id_t& id, _creator_t cf) {
    assert(!_creator_registered(id));
    _creator_map()[id] = cf;
}

/** Serialization ``writes'' the object to an output stream, which
 *  helps to store, transport, and transform the object. See
 *  C++ FAQ Lite 35 for a technical overview.
 *
 *  @param os Output stream
 *  @param vl A list of version numbers (from its descendants)
 *  @sa operator<<(std::ostream&, const Object&)
 *
 *  The first part of serialization must be the class name in full
 *  (with namespaces if any) followed by a list of version numbers
 *  from itself and its ancestors. A version number gives <EM>the
 *  version of the serialization format</EM>, but not the version
 *  of an object.
 *
 *  A class that adds some data to its parent's serialization should
 *  call serialize() of its parent with its own version number appended
 *  to @a vl. Eventually Object::serialize() is called to output the
 *  class id and the list of versions.
 *
 *  @note A zero version number is reserved for pre-0.1 format.
 *  @todo serialize() should both return false and set os's state
 *  when fail
 */
bool Object::serialize (std::ostream& os, ver_list& vl) const {
    assert(vl.size() > 0);
    ver_list::const_iterator p = vl.begin();
    os << "# " << id() << " v" << *p;
    for (++p; p != vl.end(); ++p)
        os << '.' << *p;
    os << '\n';
    return true;
}

static bool _get_id_ver (std::istream& is, Object::id_t& id,
                         std::vector<UINT>& vl) {
    assert(vl.empty());
    const UINT ignore_size = 512;

    // get the comment char #
    char c;
    if (!(is >> c)) return false;
    if (c != '#') {
        std::cerr << "_get_id_ver: Warning: # expected\n";
        is.ignore(ignore_size, '#');
    }

    // get the rest of the line
    char line[ignore_size];
    is.getline(line, ignore_size);
    std::istringstream iss(line);

    // get the identity (class name)
    if (!(iss >> id)) {
        std::cerr << "_get_id_ver: Error: no class id?\n";
        return false;
    }

    // get the version
    vl.push_back(0); // we use 0 for unspecified versions
    iss.ignore(ignore_size, 'v');
    UINT v;
    while (iss >> v) {
        assert(v > 0);
        vl.push_back(v);
        iss.ignore(1);
    }
    if (vl.size() == 1) {
        std::cerr << "_get_id_ver: Warning: pre-0.1 file format\n";
        if (id == "AdaBoost.M1") id = "AdaBoost";
        if (id.substr(0, 7) != "lemga::") id.insert(0, "lemga::");
    }

    return true;
}

/**
 *  @todo better exception; documentation
 *  @sa _register_creator, Object::unserialize, C++ FAQ Lite 35.8
 */
Object* Object::create (std::istream& is) {
    id_t _id;
    ver_list vl;
    if (!_get_id_ver(is, _id, vl)) return 0;
    assert(vl[0] == 0);

    if (_creator_registered(_id)) {
        Object* p = _creator_map()[_id]();
        bool loaded = p->unserialize(is, vl, _id);
        if (loaded && vl.size() == 1)
            return p;
        else if (loaded)
            std::cerr << _id << "::create: newer format encountered\n";
        delete p;
    } else
        std::cerr << "Class (" << _id << ") not regiestered\n";

    return 0;
}

std::istream& operator>> (std::istream& is, Object& obj) {
    Object::id_t id;
    Object::ver_list vl;

    // unserialize() judges whether id and obj are compatible
    if (!_get_id_ver(is, id, vl) || !obj.unserialize(is, vl, id)) {
        std::cerr << "operator>>: something wrong...\n";
        is.setstate(std::ios::badbit);
    } else if (vl.size() > 1) {
        std::cerr << "operator>>: newer format encountered\n";
        is.setstate(std::ios::badbit);
    }
    assert(vl[0] == 0);

    return is;
}
