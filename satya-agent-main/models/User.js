const crypto = require('crypto');

const usersMap = new Map();

class User {
    constructor(data) {
        Object.assign(this, data);
        if (!this._id) this._id = crypto.randomUUID();
    }

    async save() {
        usersMap.set(this.email, this);
        return this;
    }

    static async findOne(query) {
        if (query.email) {
            return usersMap.get(query.email) || null;
        }
        return null;
    }

    static async create(data) {
        const user = new User(data);
        usersMap.set(user.email, user);
        return user;
    }
}

module.exports = User;
