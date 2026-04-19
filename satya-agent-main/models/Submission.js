const submissionsMap = new Map();

class Submission {
    constructor(data) {
        Object.assign(this, data);
        if (!this.createdAt) this.createdAt = new Date();
    }

    static async findOneAndUpdate(query, update, options) {
        const id = query.id;
        let sub = submissionsMap.get(id);

        if (!sub && options && options.upsert) {
            sub = new Submission({ id });
        } else if (!sub) {
            return null;
        }

        const setUpdates = update.$set || {};
        Object.assign(sub, setUpdates);
        submissionsMap.set(id, sub);
        return sub;
    }

    static async find() {
        // Return a mock object with a .sort() method to support the route chaining
        return {
            sort: () => Array.from(submissionsMap.values()).sort((a, b) => b.createdAt - a.createdAt)
        };
    }

    static async findOne(query) {
        if (query.id) {
            return submissionsMap.get(query.id) || null;
        }
        return null;
    }
}

module.exports = Submission;
