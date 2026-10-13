-- Test c++ code to run in our funny transpiler thing.
local option1 = [[
#include <iostream>

int add(int a, int b) {
    return a + b;
}

int main() {
    int x = 5;
    int y = 10;
    int result = add(x, y);

    for (int i = 0; i < 3; i++) {
        result += i;
    }

    std::cout << result << '\n';
    return result;
}
]]
local option2 = [[
    //@prag LuauProton = { squB = eLineCheck } || can be "dLineCheck"
    #include <iostream>
    #include <vector>
    #include <string>
    #include <map>
    #include <memory>
    #include <algorithm>
    #include <cmath>
    #include <cassert>

    namespace TestNamespace {

    class BaseEntity {
    public:
        BaseEntity() : id_(0), active_(true) {}
        virtual ~BaseEntity() {}

        virtual void update(float dt) = 0;
        virtual void render() const = 0;

        int getId() const { return id_; }
        void setId(int id) { id_ = id; }

        bool isActive() const { return active_; }
        void setActive(bool active) { active_ = active; }

    protected:
        int id_;
        bool active_;
    };

    class Player : public BaseEntity {
    public:
        Player() : health_(100.0f), speed_(5.0f), score_(0) {}
        explicit Player(int id) : Player() { setId(id); }

        void update(float dt) override {
            if (!isActive()) return;
            position_x_ += velocity_x_ * dt * speed_;
            position_y_ += velocity_y_ * dt * speed_;
            if (health_ <= 0.0f) {
                setActive(false);
            }
        }

        void render() const override {
            if (!isActive()) return;
            // placeholder render
        }

        void takeDamage(float amount) {
            health_ -= amount;
            if (health_ < 0.0f) health_ = 0.0f;
        }

        void heal(float amount) {
            health_ += amount;
            if (health_ > 100.0f) health_ = 100.0f;
        }

        void addScore(int points) { score_ += points; }
        int getScore() const { return score_; }
        float getHealth() const { return health_; }

        void setVelocity(float vx, float vy) {
            velocity_x_ = vx;
            velocity_y_ = vy;
        }

    private:
        float health_;
        float speed_;
        int score_;
        float position_x_ = 0.0f;
        float position_y_ = 0.0f;
        float velocity_x_ = 0.0f;
        float velocity_y_ = 0.0f;
    };

    class Enemy : public BaseEntity {
    public:
        enum class Type { Grunt, Elite, Boss };

        Enemy() : type_(Type::Grunt), damage_(10.0f), health_(50.0f) {}
        Enemy(Type t, float dmg, float hp) : type_(t), damage_(dmg), health_(hp) {}

        void update(float dt) override {
            if (!isActive()) return;
            // simple AI placeholder
            patrolTimer_ += dt;
            if (patrolTimer_ > 2.0f) {
                direction_ *= -1.0f;
                patrolTimer_ = 0.0f;
            }
            position_x_ += direction_ * 2.0f * dt;
        }

        void render() const override {
            if (!isActive()) return;
        }

        float getDamage() const { return damage_; }
        Type getType() const { return type_; }

        void takeDamage(float amount) {
            health_ -= amount;
            if (health_ <= 0.0f) {
                setActive(false);
            }
        }

    private:
        Type type_;
        float damage_;
        float health_;
        float position_x_ = 0.0f;
        float direction_ = 1.0f;
        float patrolTimer_ = 0.0f;
    };

    class Projectile {
    public:
        Projectile() : alive_(false) {}
        Projectile(float x, float y, float vx, float vy, float dmg)
            : pos_x_(x), pos_y_(y), vel_x_(vx), vel_y_(vy), damage_(dmg), alive_(true) {}

        void update(float dt) {
            if (!alive_) return;
            pos_x_ += vel_x_ * dt;
            pos_y_ += vel_y_ * dt;
            lifetime_ += dt;
            if (lifetime_ > 3.0f) alive_ = false;
        }

        bool isAlive() const { return alive_; }
        float getDamage() const { return damage_; }
        float getX() const { return pos_x_; }
        float getY() const { return pos_y_; }

        void kill() { alive_ = false; }

    private:
        float pos_x_ = 0.0f;
        float pos_y_ = 0.0f;
        float vel_x_ = 0.0f;
        float vel_y_ = 0.0f;
        float damage_ = 0.0f;
        float lifetime_ = 0.0f;
        bool alive_ = false;
    };

    class GameWorld {
    public:
        GameWorld() {
            player_ = std::make_unique<Player>(1);
            spawnEnemies(20);
        }

        void spawnEnemies(int count) {
            for (int i = 0; i < count; ++i) {
                Enemy::Type t = (i % 5 == 0) ? Enemy::Type::Elite : Enemy::Type::Grunt;
                float dmg = (t == Enemy::Type::Elite) ? 25.0f : 10.0f;
                float hp  = (t == Enemy::Type::Elite) ? 120.0f : 50.0f;
                enemies_.emplace_back(t, dmg, hp);
                enemies_.back().setId(100 + i);
            }
        }

        void update(float dt) {
            if (player_) player_->update(dt);

            for (auto& e : enemies_) {
                if (e.isActive()) e.update(dt);
            }

            for (auto& p : projectiles_) {
                p.update(dt);
            }

            // simple collision placeholder
            for (auto& p : projectiles_) {
                if (!p.isAlive()) continue;
                for (auto& e : enemies_) {
                    if (!e.isActive()) continue;
                    // pretend hit
                    if (std::abs(p.getX() - 0.0f) < 1.0f) {
                        e.takeDamage(p.getDamage());
                        p.kill();
                        if (player_) player_->addScore(10);
                    }
                }
            }

            // cleanup dead projectiles
            projectiles_.erase(
                std::remove_if(projectiles_.begin(), projectiles_.end(),
                    [](const Projectile& p) { return !p.isAlive(); }),
                projectiles_.end());
        }

        void render() const {
            if (player_) player_->render();
            for (const auto& e : enemies_) {
                if (e.isActive()) e.render();
            }
        }

        void fireProjectile(float x, float y, float vx, float vy, float dmg) {
            projectiles_.emplace_back(x, y, vx, vy, dmg);
        }

        Player* getPlayer() { return player_.get(); }
        const std::vector<Enemy>& getEnemies() const { return enemies_; }

    private:
        std::unique_ptr<Player> player_;
        std::vector<Enemy> enemies_;
        std::vector<Projectile> projectiles_;
    };

    // ---------- repetitive helper functions to pad line count ----------

    int add(int a, int b) { return a + b; }
    int sub(int a, int b) { return a - b; }
    int mul(int a, int b) { return a * b; }
    int div_safe(int a, int b) { return b != 0 ? a / b : 0; }

    float addf(float a, float b) { return a + b; }
    float subf(float a, float b) { return a - b; }
    float mulf(float a, float b) { return a * b; }
    float divf(float a, float b) { return b != 0.0f ? a / b : 0.0f; }

    bool isEven(int n) { return n % 2 == 0; }
    bool isOdd(int n) { return n % 2 != 0; }
    bool isPositive(int n) { return n > 0; }
    bool isNegative(int n) { return n < 0; }

    int clampInt(int v, int lo, int hi) {
        if (v < lo) return lo;
        if (v > hi) return hi;
        return v;
    }

    float clampFloat(float v, float lo, float hi) {
        if (v < lo) return lo;
        if (v > hi) return hi;
        return v;
    }

    int maxInt(int a, int b) { return a > b ? a : b; }
    int minInt(int a, int b) { return a < b ? a : b; }
    float maxFloat(float a, float b) { return a > b ? a : b; }
    float minFloat(float a, float b) { return a < b ? a : b; }

    // generate a lot of nearly identical utility functions
    int util001(int x) { return x * 1 + 1; }
    int util002(int x) { return x * 2 + 2; }
    int util003(int x) { return x * 3 + 3; }
    int util004(int x) { return x * 4 + 4; }
    int util005(int x) { return x * 5 + 5; }
    int util006(int x) { return x * 6 + 6; }
    int util007(int x) { return x * 7 + 7; }
    int util008(int x) { return x * 8 + 8; }
    int util009(int x) { return x * 9 + 9; }
    int util010(int x) { return x * 10 + 10; }
    int util011(int x) { return x * 11 + 11; }
    int util012(int x) { return x * 12 + 12; }
    int util013(int x) { return x * 13 + 13; }
    int util014(int x) { return x * 14 + 14; }
    int util015(int x) { return x * 15 + 15; }
    int util016(int x) { return x * 16 + 16; }
    int util017(int x) { return x * 17 + 17; }
    int util018(int x) { return x * 18 + 18; }
    int util019(int x) { return x * 19 + 19; }
    int util020(int x) { return x * 20 + 20; }
    int util021(int x) { return x * 21 + 21; }
    int util022(int x) { return x * 22 + 22; }
    int util023(int x) { return x * 23 + 23; }
    int util024(int x) { return x * 24 + 24; }
    int util025(int x) { return x * 25 + 25; }
    int util026(int x) { return x * 26 + 26; }
    int util027(int x) { return x * 27 + 27; }
    int util028(int x) { return x * 28 + 28; }
    int util029(int x) { return x * 29 + 29; }
    int util030(int x) { return x * 30 + 30; }
    int util031(int x) { return x * 31 + 31; }
    int util032(int x) { return x * 32 + 32; }
    int util033(int x) { return x * 33 + 33; }
    int util034(int x) { return x * 34 + 34; }
    int util035(int x) { return x * 35 + 35; }
    int util036(int x) { return x * 36 + 36; }
    int util037(int x) { return x * 37 + 37; }
    int util038(int x) { return x * 38 + 38; }
    int util039(int x) { return x * 39 + 39; }
    int util040(int x) { return x * 40 + 40; }
    int util041(int x) { return x * 41 + 41; }
    int util042(int x) { return x * 42 + 42; }
    int util043(int x) { return x * 43 + 43; }
    int util044(int x) { return x * 44 + 44; }
    int util045(int x) { return x * 45 + 45; }
    int util046(int x) { return x * 46 + 46; }
    int util047(int x) { return x * 47 + 47; }
    int util048(int x) { return x * 48 + 48; }
    int util049(int x) { return x * 49 + 49; }
    int util050(int x) { return x * 50 + 50; }
    int util051(int x) { return x * 51 + 51; }
    int util052(int x) { return x * 52 + 52; }
    int util053(int x) { return x * 53 + 53; }
    int util054(int x) { return x * 54 + 54; }
    int util055(int x) { return x * 55 + 55; }
    int util056(int x) { return x * 56 + 56; }
    int util057(int x) { return x * 57 + 57; }
    int util058(int x) { return x * 58 + 58; }
    int util059(int x) { return x * 59 + 59; }
    int util060(int x) { return x * 60 + 60; }
    int util061(int x) { return x * 61 + 61; }
    int util062(int x) { return x * 62 + 62; }
    int util063(int x) { return x * 63 + 63; }
    int util064(int x) { return x * 64 + 64; }
    int util065(int x) { return x * 65 + 65; }
    int util066(int x) { return x * 66 + 66; }
    int util067(int x) { return x * 67 + 67; }
    int util068(int x) { return x * 68 + 68; }
    int util069(int x) { return x * 69 + 69; }
    int util070(int x) { return x * 70 + 70; }
    int util071(int x) { return x * 71 + 71; }
    int util072(int x) { return x * 72 + 72; }
    int util073(int x) { return x * 73 + 73; }
    int util074(int x) { return x * 74 + 74; }
    int util075(int x) { return x * 75 + 75; }
    int util076(int x) { return x * 76 + 76; }
    int util077(int x) { return x * 77 + 77; }
    int util078(int x) { return x * 78 + 78; }
    int util079(int x) { return x * 79 + 79; }
    int util080(int x) { return x * 80 + 80; }
    int util081(int x) { return x * 81 + 81; }
    int util082(int x) { return x * 82 + 82; }
    int util083(int x) { return x * 83 + 83; }
    int util084(int x) { return x * 84 + 84; }
    int util085(int x) { return x * 85 + 85; }
    int util086(int x) { return x * 86 + 86; }
    int util087(int x) { return x * 87 + 87; }
    int util088(int x) { return x * 88 + 88; }
    int util089(int x) { return x * 89 + 89; }
    int util090(int x) { return x * 90 + 90; }
    int util091(int x) { return x * 91 + 91; }
    int util092(int x) { return x * 92 + 92; }
    int util093(int x) { return x * 93 + 93; }
    int util094(int x) { return x * 94 + 94; }
    int util095(int x) { return x * 95 + 95; }
    int util096(int x) { return x * 96 + 96; }
    int util097(int x) { return x * 97 + 97; }
    int util098(int x) { return x * 98 + 98; }
    int util099(int x) { return x * 99 + 99; }
    int util100(int x) { return x * 100 + 100; }

    // more padding with loops and conditionals
    void processBatch1(std::vector<int>& data) {
        for (size_t i = 0; i < data.size(); ++i) {
            if (data[i] < 0) data[i] = 0;
            else if (data[i] > 1000) data[i] = 1000;
            data[i] = data[i] * 2 + 1;
        }
    }

    void processBatch2(std::vector<int>& data) {
        for (size_t i = 0; i < data.size(); ++i) {
            if (isEven(data[i])) data[i] += 10;
            else data[i] -= 5;
        }
    }

    void processBatch3(std::vector<float>& data) {
        for (size_t i = 0; i < data.size(); ++i) {
            data[i] = clampFloat(data[i], 0.0f, 1.0f);
            data[i] = data[i] * data[i];
        }
    }

    void fillSequence(std::vector<int>& out, int count) {
        out.clear();
        out.reserve(count);
        for (int i = 0; i < count; ++i) {
            out.push_back(i * 3 + 7);
        }
    }

    int sumRange(const std::vector<int>& v, int start, int end) {
        int s = 0;
        for (int i = start; i < end && i < static_cast<int>(v.size()); ++i) {
            s += v[i];
        }
        return s;
    }

    float average(const std::vector<float>& v) {
        if (v.empty()) return 0.0f;
        float s = 0.0f;
        for (float x : v) s += x;
        return s / static_cast<float>(v.size());
    }

    // large block of repetitive switch / if logic
    int classify(int value) {
        switch (value % 10) {
            case 0: return 100;
            case 1: return 101;
            case 2: return 102;
            case 3: return 103;
            case 4: return 104;
            case 5: return 105;
            case 6: return 106;
            case 7: return 107;
            case 8: return 108;
            case 9: return 109;
            default: return -1;
        }
    }

    int classify2(int value) {
        if (value < 0) return -1;
        if (value < 10) return 0;
        if (value < 20) return 1;
        if (value < 30) return 2;
        if (value < 40) return 3;
        if (value < 50) return 4;
        if (value < 60) return 5;
        if (value < 70) return 6;
        if (value < 80) return 7;
        if (value < 90) return 8;
        return 9;
    }
    #include <iostream>
    
    int add(int a, int b) {
        return a + b;
    }
    
    int main() {
        int x = 5;
        int y = 10;
        int result = add(x, y);
    
        for (int i = 0; i < 3; i++) {
            result += i;
        }
    
        std::cout << result << '\n';
        return result;
    }
        //@prag LuauProton = { squB = eLineCheck } || can be "dLineCheck"
        #include <iostream>
        #include <vector>
        #include <string>
        #include <map>
        #include <memory>
        #include <algorithm>
        #include <cmath>
        #include <cassert>
    
        namespace TestNamespace {
    
        class BaseEntity {
        public:
            BaseEntity() : id_(0), active_(true) {}
            virtual ~BaseEntity() {}
    
            virtual void update(float dt) = 0;
            virtual void render() const = 0;
    
            int getId() const { return id_; }
            void setId(int id) { id_ = id; }
    
            bool isActive() const { return active_; }
            void setActive(bool active) { active_ = active; }
    
        protected:
            int id_;
            bool active_;
        };
    
        class Player : public BaseEntity {
        public:
            Player() : health_(100.0f), speed_(5.0f), score_(0) {}
            explicit Player(int id) : Player() { setId(id); }
    
            void update(float dt) override {
                if (!isActive()) return;
                position_x_ += velocity_x_ * dt * speed_;
                position_y_ += velocity_y_ * dt * speed_;
                if (health_ <= 0.0f) {
                    setActive(false);
                }
            }
    
            void render() const override {
                if (!isActive()) return;
                // placeholder render
            }
    
            void takeDamage(float amount) {
                health_ -= amount;
                if (health_ < 0.0f) health_ = 0.0f;
            }
    
            void heal(float amount) {
                health_ += amount;
                if (health_ > 100.0f) health_ = 100.0f;
            }
    
            void addScore(int points) { score_ += points; }
            int getScore() const { return score_; }
            float getHealth() const { return health_; }
    
            void setVelocity(float vx, float vy) {
                velocity_x_ = vx;
                velocity_y_ = vy;
            }
    
        private:
            float health_;
            float speed_;
            int score_;
            float position_x_ = 0.0f;
            float position_y_ = 0.0f;
            float velocity_x_ = 0.0f;
            float velocity_y_ = 0.0f;
        };
    
        class Enemy : public BaseEntity {
        public:
            enum class Type { Grunt, Elite, Boss };
    
            Enemy() : type_(Type::Grunt), damage_(10.0f), health_(50.0f) {}
            Enemy(Type t, float dmg, float hp) : type_(t), damage_(dmg), health_(hp) {}
    
            void update(float dt) override {
                if (!isActive()) return;
                // simple AI placeholder
                patrolTimer_ += dt;
                if (patrolTimer_ > 2.0f) {
                    direction_ *= -1.0f;
                    patrolTimer_ = 0.0f;
                }
                position_x_ += direction_ * 2.0f * dt;
            }
    
            void render() const override {
                if (!isActive()) return;
            }
    
            float getDamage() const { return damage_; }
            Type getType() const { return type_; }
    
            void takeDamage(float amount) {
                health_ -= amount;
                if (health_ <= 0.0f) {
                    setActive(false);
                }
            }
    
        private:
            Type type_;
            float damage_;
            float health_;
            float position_x_ = 0.0f;
            float direction_ = 1.0f;
            float patrolTimer_ = 0.0f;
        };
    
        class Projectile {
        public:
            Projectile() : alive_(false) {}
            Projectile(float x, float y, float vx, float vy, float dmg)
                : pos_x_(x), pos_y_(y), vel_x_(vx), vel_y_(vy), damage_(dmg), alive_(true) {}
    
            void update(float dt) {
                if (!alive_) return;
                pos_x_ += vel_x_ * dt;
                pos_y_ += vel_y_ * dt;
                lifetime_ += dt;
                if (lifetime_ > 3.0f) alive_ = false;
            }
    
            bool isAlive() const { return alive_; }
            float getDamage() const { return damage_; }
            float getX() const { return pos_x_; }
            float getY() const { return pos_y_; }
    
            void kill() { alive_ = false; }
    
        private:
            float pos_x_ = 0.0f;
            float pos_y_ = 0.0f;
            float vel_x_ = 0.0f;
            float vel_y_ = 0.0f;
            float damage_ = 0.0f;
            float lifetime_ = 0.0f;
            bool alive_ = false;
        };
    
        class GameWorld {
        public:
            GameWorld() {
                player_ = std::make_unique<Player>(1);
                spawnEnemies(20);
            }
    
            void spawnEnemies(int count) {
                for (int i = 0; i < count; ++i) {
                    Enemy::Type t = (i % 5 == 0) ? Enemy::Type::Elite : Enemy::Type::Grunt;
                    float dmg = (t == Enemy::Type::Elite) ? 25.0f : 10.0f;
                    float hp  = (t == Enemy::Type::Elite) ? 120.0f : 50.0f;
                    enemies_.emplace_back(t, dmg, hp);
                    enemies_.back().setId(100 + i);
                }
            }
    
            void update(float dt) {
                if (player_) player_->update(dt);
    
                for (auto& e : enemies_) {
                    if (e.isActive()) e.update(dt);
                }
    
                for (auto& p : projectiles_) {
                    p.update(dt);
                }
    
                // simple collision placeholder
                for (auto& p : projectiles_) {
                    if (!p.isAlive()) continue;
                    for (auto& e : enemies_) {
                        if (!e.isActive()) continue;
                        // pretend hit
                        if (std::abs(p.getX() - 0.0f) < 1.0f) {
                            e.takeDamage(p.getDamage());
                            p.kill();
                            if (player_) player_->addScore(10);
                        }
                    }
                }
    
                // cleanup dead projectiles
                projectiles_.erase(
                    std::remove_if(projectiles_.begin(), projectiles_.end(),
                        [](const Projectile& p) { return !p.isAlive(); }),
                    projectiles_.end());
            }
    
            void render() const {
                if (player_) player_->render();
                for (const auto& e : enemies_) {
                    if (e.isActive()) e.render();
                }
            }
    
            void fireProjectile(float x, float y, float vx, float vy, float dmg) {
                projectiles_.emplace_back(x, y, vx, vy, dmg);
            }
    
            Player* getPlayer() { return player_.get(); }
            const std::vector<Enemy>& getEnemies() const { return enemies_; }
    
        private:
            std::unique_ptr<Player> player_;
            std::vector<Enemy> enemies_;
            std::vector<Projectile> projectiles_;
        };
    
        // ---------- repetitive helper functions to pad line count ----------
    
        int add(int a, int b) { return a + b; }
        int sub(int a, int b) { return a - b; }
        int mul(int a, int b) { return a * b; }
        int div_safe(int a, int b) { return b != 0 ? a / b : 0; }
    
        float addf(float a, float b) { return a + b; }
        float subf(float a, float b) { return a - b; }
        float mulf(float a, float b) { return a * b; }
        float divf(float a, float b) { return b != 0.0f ? a / b : 0.0f; }
    
        bool isEven(int n) { return n % 2 == 0; }
        bool isOdd(int n) { return n % 2 != 0; }
        bool isPositive(int n) { return n > 0; }
        bool isNegative(int n) { return n < 0; }
    
        int clampInt(int v, int lo, int hi) {
            if (v < lo) return lo;
            if (v > hi) return hi;
            return v;
        }
    
        float clampFloat(float v, float lo, float hi) {
            if (v < lo) return lo;
            if (v > hi) return hi;
            return v;
        }
    
        int maxInt(int a, int b) { return a > b ? a : b; }
        int minInt(int a, int b) { return a < b ? a : b; }
        float maxFloat(float a, float b) { return a > b ? a : b; }
        float minFloat(float a, float b) { return a < b ? a : b; }
    
        // generate a lot of nearly identical utility functions
        int util001(int x) { return x * 1 + 1; }
        int util002(int x) { return x * 2 + 2; }
        int util003(int x) { return x * 3 + 3; }
        int util004(int x) { return x * 4 + 4; }
        int util005(int x) { return x * 5 + 5; }
        int util006(int x) { return x * 6 + 6; }
        int util007(int x) { return x * 7 + 7; }
        int util008(int x) { return x * 8 + 8; }
        int util009(int x) { return x * 9 + 9; }
        int util010(int x) { return x * 10 + 10; }
        int util011(int x) { return x * 11 + 11; }
        int util012(int x) { return x * 12 + 12; }
        int util013(int x) { return x * 13 + 13; }
        int util014(int x) { return x * 14 + 14; }
        int util015(int x) { return x * 15 + 15; }
        int util016(int x) { return x * 16 + 16; }
        int util017(int x) { return x * 17 + 17; }
        int util018(int x) { return x * 18 + 18; }
        int util019(int x) { return x * 19 + 19; }
        int util020(int x) { return x * 20 + 20; }
        int util021(int x) { return x * 21 + 21; }
        int util022(int x) { return x * 22 + 22; }
        int util023(int x) { return x * 23 + 23; }
        int util024(int x) { return x * 24 + 24; }
        int util025(int x) { return x * 25 + 25; }
        int util026(int x) { return x * 26 + 26; }
        int util027(int x) { return x * 27 + 27; }
        int util028(int x) { return x * 28 + 28; }
        int util029(int x) { return x * 29 + 29; }
        int util030(int x) { return x * 30 + 30; }
        int util031(int x) { return x * 31 + 31; }
        int util032(int x) { return x * 32 + 32; }
        int util033(int x) { return x * 33 + 33; }
        int util034(int x) { return x * 34 + 34; }
        int util035(int x) { return x * 35 + 35; }
        int util036(int x) { return x * 36 + 36; }
        int util037(int x) { return x * 37 + 37; }
        int util038(int x) { return x * 38 + 38; }
        int util039(int x) { return x * 39 + 39; }
        int util040(int x) { return x * 40 + 40; }
        int util041(int x) { return x * 41 + 41; }
        int util042(int x) { return x * 42 + 42; }
        int util043(int x) { return x * 43 + 43; }
        int util044(int x) { return x * 44 + 44; }
        int util045(int x) { return x * 45 + 45; }
        int util046(int x) { return x * 46 + 46; }
        int util047(int x) { return x * 47 + 47; }
        int util048(int x) { return x * 48 + 48; }
        int util049(int x) { return x * 49 + 49; }
        int util050(int x) { return x * 50 + 50; }
        int util051(int x) { return x * 51 + 51; }
        int util052(int x) { return x * 52 + 52; }
        int util053(int x) { return x * 53 + 53; }
        int util054(int x) { return x * 54 + 54; }
        int util055(int x) { return x * 55 + 55; }
        int util056(int x) { return x * 56 + 56; }
        int util057(int x) { return x * 57 + 57; }
        int util058(int x) { return x * 58 + 58; }
        int util059(int x) { return x * 59 + 59; }
        int util060(int x) { return x * 60 + 60; }
        int util061(int x) { return x * 61 + 61; }
        int util062(int x) { return x * 62 + 62; }
        int util063(int x) { return x * 63 + 63; }
        int util064(int x) { return x * 64 + 64; }
        int util065(int x) { return x * 65 + 65; }
        int util066(int x) { return x * 66 + 66; }
        int util067(int x) { return x * 67 + 67; }
        int util068(int x) { return x * 68 + 68; }
        int util069(int x) { return x * 69 + 69; }
        int util070(int x) { return x * 70 + 70; }
        int util071(int x) { return x * 71 + 71; }
        int util072(int x) { return x * 72 + 72; }
        int util073(int x) { return x * 73 + 73; }
        int util074(int x) { return x * 74 + 74; }
        int util075(int x) { return x * 75 + 75; }
        int util076(int x) { return x * 76 + 76; }
        int util077(int x) { return x * 77 + 77; }
        int util078(int x) { return x * 78 + 78; }
        int util079(int x) { return x * 79 + 79; }
        int util080(int x) { return x * 80 + 80; }
        int util081(int x) { return x * 81 + 81; }
        int util082(int x) { return x * 82 + 82; }
        int util083(int x) { return x * 83 + 83; }
        int util084(int x) { return x * 84 + 84; }
        int util085(int x) { return x * 85 + 85; }
        int util086(int x) { return x * 86 + 86; }
        int util087(int x) { return x * 87 + 87; }
        int util088(int x) { return x * 88 + 88; }
        int util089(int x) { return x * 89 + 89; }
        int util090(int x) { return x * 90 + 90; }
        int util091(int x) { return x * 91 + 91; }
        int util092(int x) { return x * 92 + 92; }
        int util093(int x) { return x * 93 + 93; }
        int util094(int x) { return x * 94 + 94; }
        int util095(int x) { return x * 95 + 95; }
        int util096(int x) { return x * 96 + 96; }
        int util097(int x) { return x * 97 + 97; }
        int util098(int x) { return x * 98 + 98; }
        int util099(int x) { return x * 99 + 99; }
        int util100(int x) { return x * 100 + 100; }
    
        // more padding with loops and conditionals
        void processBatch1(std::vector<int>& data) {
            for (size_t i = 0; i < data.size(); ++i) {
                if (data[i] < 0) data[i] = 0;
                else if (data[i] > 1000) data[i] = 1000;
                data[i] = data[i] * 2 + 1;
            }
        }
    
        void processBatch2(std::vector<int>& data) {
            for (size_t i = 0; i < data.size(); ++i) {
                if (isEven(data[i])) data[i] += 10;
                else data[i] -= 5;
            }
        }
    
        void processBatch3(std::vector<float>& data) {
            for (size_t i = 0; i < data.size(); ++i) {
                data[i] = clampFloat(data[i], 0.0f, 1.0f);
                data[i] = data[i] * data[i];
            }
        }
    
        void fillSequence(std::vector<int>& out, int count) {
            out.clear();
            out.reserve(count);
            for (int i = 0; i < count; ++i) {
                out.push_back(i * 3 + 7);
            }
        }
    
        int sumRange(const std::vector<int>& v, int start, int end) {
            int s = 0;
            for (int i = start; i < end && i < static_cast<int>(v.size()); ++i) {
                s += v[i];
            }
            return s;
        }
    
        float average(const std::vector<float>& v) {
            if (v.empty()) return 0.0f;
            float s = 0.0f;
            for (float x : v) s += x;
            return s / static_cast<float>(v.size());
        }
    
        // large block of repetitive switch / if logic
        int classify(int value) {
            switch (value % 10) {
                case 0: return 100;
                case 1: return 101;
                case 2: return 102;
                case 3: return 103;
                case 4: return 104;
                case 5: return 105;
                case 6: return 106;
                case 7: return 107;
                case 8: return 108;
                case 9: return 109;
                default: return -1;
            }
        }
    
        int classify2(int value) {
            if (value < 0) return -1;
            if (value < 10) return 0;
            if (value < 20) return 1;
            if (value < 30) return 2;
            if (value < 40) return 3;
            if (value < 50) return 4;
            if (value < 60) return 5;
            if (value < 70) return 6;
            if (value < 80) return 7;
            if (value < 90) return 8;
            return 9;
        }
        #include <iostream>
        
        int add(int a, int b) {
            return a + b;
        }
        
        int main() {
            int x = 5;
            int y = 10;
            int result = add(x, y);
        
            for (int i = 0; i < 3; i++) {
                result += i;
            }
        
            std::cout << result << '\n';
            return result;
        }
            //@prag LuauProton = { squB = eLineCheck } || can be "dLineCheck"
            #include <iostream>
            #include <vector>
            #include <string>
            #include <map>
            #include <memory>
            #include <algorithm>
            #include <cmath>
            #include <cassert>
        
            namespace TestNamespace {
        
            class BaseEntity {
            public:
                BaseEntity() : id_(0), active_(true) {}
                virtual ~BaseEntity() {}
        
                virtual void update(float dt) = 0;
                virtual void render() const = 0;
        
                int getId() const { return id_; }
                void setId(int id) { id_ = id; }
        
                bool isActive() const { return active_; }
                void setActive(bool active) { active_ = active; }
        
            protected:
                int id_;
                bool active_;
            };
        
            class Player : public BaseEntity {
            public:
                Player() : health_(100.0f), speed_(5.0f), score_(0) {}
                explicit Player(int id) : Player() { setId(id); }
        
                void update(float dt) override {
                    if (!isActive()) return;
                    position_x_ += velocity_x_ * dt * speed_;
                    position_y_ += velocity_y_ * dt * speed_;
                    if (health_ <= 0.0f) {
                        setActive(false);
                    }
                }
        
                void render() const override {
                    if (!isActive()) return;
                    // placeholder render
                }
        
                void takeDamage(float amount) {
                    health_ -= amount;
                    if (health_ < 0.0f) health_ = 0.0f;
                }
        
                void heal(float amount) {
                    health_ += amount;
                    if (health_ > 100.0f) health_ = 100.0f;
                }
        
                void addScore(int points) { score_ += points; }
                int getScore() const { return score_; }
                float getHealth() const { return health_; }
        
                void setVelocity(float vx, float vy) {
                    velocity_x_ = vx;
                    velocity_y_ = vy;
                }
        
            private:
                float health_;
                float speed_;
                int score_;
                float position_x_ = 0.0f;
                float position_y_ = 0.0f;
                float velocity_x_ = 0.0f;
                float velocity_y_ = 0.0f;
            };
        
            class Enemy : public BaseEntity {
            public:
                enum class Type { Grunt, Elite, Boss };
        
                Enemy() : type_(Type::Grunt), damage_(10.0f), health_(50.0f) {}
                Enemy(Type t, float dmg, float hp) : type_(t), damage_(dmg), health_(hp) {}
        
                void update(float dt) override {
                    if (!isActive()) return;
                    // simple AI placeholder
                    patrolTimer_ += dt;
                    if (patrolTimer_ > 2.0f) {
                        direction_ *= -1.0f;
                        patrolTimer_ = 0.0f;
                    }
                    position_x_ += direction_ * 2.0f * dt;
                }
        
                void render() const override {
                    if (!isActive()) return;
                }
        
                float getDamage() const { return damage_; }
                Type getType() const { return type_; }
        
                void takeDamage(float amount) {
                    health_ -= amount;
                    if (health_ <= 0.0f) {
                        setActive(false);
                    }
                }
        
            private:
                Type type_;
                float damage_;
                float health_;
                float position_x_ = 0.0f;
                float direction_ = 1.0f;
                float patrolTimer_ = 0.0f;
            };
        
            class Projectile {
            public:
                Projectile() : alive_(false) {}
                Projectile(float x, float y, float vx, float vy, float dmg)
                    : pos_x_(x), pos_y_(y), vel_x_(vx), vel_y_(vy), damage_(dmg), alive_(true) {}
        
                void update(float dt) {
                    if (!alive_) return;
                    pos_x_ += vel_x_ * dt;
                    pos_y_ += vel_y_ * dt;
                    lifetime_ += dt;
                    if (lifetime_ > 3.0f) alive_ = false;
                }
        
                bool isAlive() const { return alive_; }
                float getDamage() const { return damage_; }
                float getX() const { return pos_x_; }
                float getY() const { return pos_y_; }
        
                void kill() { alive_ = false; }
        
            private:
                float pos_x_ = 0.0f;
                float pos_y_ = 0.0f;
                float vel_x_ = 0.0f;
                float vel_y_ = 0.0f;
                float damage_ = 0.0f;
                float lifetime_ = 0.0f;
                bool alive_ = false;
            };
        
            class GameWorld {
            public:
                GameWorld() {
                    player_ = std::make_unique<Player>(1);
                    spawnEnemies(20);
                }
        
                void spawnEnemies(int count) {
                    for (int i = 0; i < count; ++i) {
                        Enemy::Type t = (i % 5 == 0) ? Enemy::Type::Elite : Enemy::Type::Grunt;
                        float dmg = (t == Enemy::Type::Elite) ? 25.0f : 10.0f;
                        float hp  = (t == Enemy::Type::Elite) ? 120.0f : 50.0f;
                        enemies_.emplace_back(t, dmg, hp);
                        enemies_.back().setId(100 + i);
                    }
                }
        
                void update(float dt) {
                    if (player_) player_->update(dt);
        
                    for (auto& e : enemies_) {
                        if (e.isActive()) e.update(dt);
                    }
        
                    for (auto& p : projectiles_) {
                        p.update(dt);
                    }
        
                    // simple collision placeholder
                    for (auto& p : projectiles_) {
                        if (!p.isAlive()) continue;
                        for (auto& e : enemies_) {
                            if (!e.isActive()) continue;
                            // pretend hit
                            if (std::abs(p.getX() - 0.0f) < 1.0f) {
                                e.takeDamage(p.getDamage());
                                p.kill();
                                if (player_) player_->addScore(10);
                            }
                        }
                    }
        
                    // cleanup dead projectiles
                    projectiles_.erase(
                        std::remove_if(projectiles_.begin(), projectiles_.end(),
                            [](const Projectile& p) { return !p.isAlive(); }),
                        projectiles_.end());
                }
        
                void render() const {
                    if (player_) player_->render();
                    for (const auto& e : enemies_) {
                        if (e.isActive()) e.render();
                    }
                }
        
                void fireProjectile(float x, float y, float vx, float vy, float dmg) {
                    projectiles_.emplace_back(x, y, vx, vy, dmg);
                }
        
                Player* getPlayer() { return player_.get(); }
                const std::vector<Enemy>& getEnemies() const { return enemies_; }
        
            private:
                std::unique_ptr<Player> player_;
                std::vector<Enemy> enemies_;
                std::vector<Projectile> projectiles_;
            };
        
            // ---------- repetitive helper functions to pad line count ----------
        
            int add(int a, int b) { return a + b; }
            int sub(int a, int b) { return a - b; }
            int mul(int a, int b) { return a * b; }
            int div_safe(int a, int b) { return b != 0 ? a / b : 0; }
        
            float addf(float a, float b) { return a + b; }
            float subf(float a, float b) { return a - b; }
            float mulf(float a, float b) { return a * b; }
            float divf(float a, float b) { return b != 0.0f ? a / b : 0.0f; }
        
            bool isEven(int n) { return n % 2 == 0; }
            bool isOdd(int n) { return n % 2 != 0; }
            bool isPositive(int n) { return n > 0; }
            bool isNegative(int n) { return n < 0; }
        
            int clampInt(int v, int lo, int hi) {
                if (v < lo) return lo;
                if (v > hi) return hi;
                return v;
            }
        
            float clampFloat(float v, float lo, float hi) {
                if (v < lo) return lo;
                if (v > hi) return hi;
                return v;
            }
        
            int maxInt(int a, int b) { return a > b ? a : b; }
            int minInt(int a, int b) { return a < b ? a : b; }
            float maxFloat(float a, float b) { return a > b ? a : b; }
            float minFloat(float a, float b) { return a < b ? a : b; }
        
            // generate a lot of nearly identical utility functions
            int util001(int x) { return x * 1 + 1; }
            int util002(int x) { return x * 2 + 2; }
            int util003(int x) { return x * 3 + 3; }
            int util004(int x) { return x * 4 + 4; }
            int util005(int x) { return x * 5 + 5; }
            int util006(int x) { return x * 6 + 6; }
            int util007(int x) { return x * 7 + 7; }
            int util008(int x) { return x * 8 + 8; }
            int util009(int x) { return x * 9 + 9; }
            int util010(int x) { return x * 10 + 10; }
            int util011(int x) { return x * 11 + 11; }
            int util012(int x) { return x * 12 + 12; }
            int util013(int x) { return x * 13 + 13; }
            int util014(int x) { return x * 14 + 14; }
            int util015(int x) { return x * 15 + 15; }
            int util016(int x) { return x * 16 + 16; }
            int util017(int x) { return x * 17 + 17; }
            int util018(int x) { return x * 18 + 18; }
            int util019(int x) { return x * 19 + 19; }
            int util020(int x) { return x * 20 + 20; }
            int util021(int x) { return x * 21 + 21; }
            int util022(int x) { return x * 22 + 22; }
            int util023(int x) { return x * 23 + 23; }
            int util024(int x) { return x * 24 + 24; }
            int util025(int x) { return x * 25 + 25; }
            int util026(int x) { return x * 26 + 26; }
            int util027(int x) { return x * 27 + 27; }
            int util028(int x) { return x * 28 + 28; }
            int util029(int x) { return x * 29 + 29; }
            int util030(int x) { return x * 30 + 30; }
            int util031(int x) { return x * 31 + 31; }
            int util032(int x) { return x * 32 + 32; }
            int util033(int x) { return x * 33 + 33; }
            int util034(int x) { return x * 34 + 34; }
            int util035(int x) { return x * 35 + 35; }
            int util036(int x) { return x * 36 + 36; }
            int util037(int x) { return x * 37 + 37; }
            int util038(int x) { return x * 38 + 38; }
            int util039(int x) { return x * 39 + 39; }
            int util040(int x) { return x * 40 + 40; }
            int util041(int x) { return x * 41 + 41; }
            int util042(int x) { return x * 42 + 42; }
            int util043(int x) { return x * 43 + 43; }
            int util044(int x) { return x * 44 + 44; }
            int util045(int x) { return x * 45 + 45; }
            int util046(int x) { return x * 46 + 46; }
            int util047(int x) { return x * 47 + 47; }
            int util048(int x) { return x * 48 + 48; }
            int util049(int x) { return x * 49 + 49; }
            int util050(int x) { return x * 50 + 50; }
            int util051(int x) { return x * 51 + 51; }
            int util052(int x) { return x * 52 + 52; }
            int util053(int x) { return x * 53 + 53; }
            int util054(int x) { return x * 54 + 54; }
            int util055(int x) { return x * 55 + 55; }
            int util056(int x) { return x * 56 + 56; }
            int util057(int x) { return x * 57 + 57; }
            int util058(int x) { return x * 58 + 58; }
            int util059(int x) { return x * 59 + 59; }
            int util060(int x) { return x * 60 + 60; }
            int util061(int x) { return x * 61 + 61; }
            int util062(int x) { return x * 62 + 62; }
            int util063(int x) { return x * 63 + 63; }
            int util064(int x) { return x * 64 + 64; }
            int util065(int x) { return x * 65 + 65; }
            int util066(int x) { return x * 66 + 66; }
            int util067(int x) { return x * 67 + 67; }
            int util068(int x) { return x * 68 + 68; }
            int util069(int x) { return x * 69 + 69; }
            int util070(int x) { return x * 70 + 70; }
            int util071(int x) { return x * 71 + 71; }
            int util072(int x) { return x * 72 + 72; }
            int util073(int x) { return x * 73 + 73; }
            int util074(int x) { return x * 74 + 74; }
            int util075(int x) { return x * 75 + 75; }
            int util076(int x) { return x * 76 + 76; }
            int util077(int x) { return x * 77 + 77; }
            int util078(int x) { return x * 78 + 78; }
            int util079(int x) { return x * 79 + 79; }
            int util080(int x) { return x * 80 + 80; }
            int util081(int x) { return x * 81 + 81; }
            int util082(int x) { return x * 82 + 82; }
            int util083(int x) { return x * 83 + 83; }
            int util084(int x) { return x * 84 + 84; }
            int util085(int x) { return x * 85 + 85; }
            int util086(int x) { return x * 86 + 86; }
            int util087(int x) { return x * 87 + 87; }
            int util088(int x) { return x * 88 + 88; }
            int util089(int x) { return x * 89 + 89; }
            int util090(int x) { return x * 90 + 90; }
            int util091(int x) { return x * 91 + 91; }
            int util092(int x) { return x * 92 + 92; }
            int util093(int x) { return x * 93 + 93; }
            int util094(int x) { return x * 94 + 94; }
            int util095(int x) { return x * 95 + 95; }
            int util096(int x) { return x * 96 + 96; }
            int util097(int x) { return x * 97 + 97; }
            int util098(int x) { return x * 98 + 98; }
            int util099(int x) { return x * 99 + 99; }
            int util100(int x) { return x * 100 + 100; }
        
            // more padding with loops and conditionals
            void processBatch1(std::vector<int>& data) {
                for (size_t i = 0; i < data.size(); ++i) {
                    if (data[i] < 0) data[i] = 0;
                    else if (data[i] > 1000) data[i] = 1000;
                    data[i] = data[i] * 2 + 1;
                }
            }
        
            void processBatch2(std::vector<int>& data) {
                for (size_t i = 0; i < data.size(); ++i) {
                    if (isEven(data[i])) data[i] += 10;
                    else data[i] -= 5;
                }
            }
        
            void processBatch3(std::vector<float>& data) {
                for (size_t i = 0; i < data.size(); ++i) {
                    data[i] = clampFloat(data[i], 0.0f, 1.0f);
                    data[i] = data[i] * data[i];
                }
            }
        
            void fillSequence(std::vector<int>& out, int count) {
                out.clear();
                out.reserve(count);
                for (int i = 0; i < count; ++i) {
                    out.push_back(i * 3 + 7);
                }
            }
        
            int sumRange(const std::vector<int>& v, int start, int end) {
                int s = 0;
                for (int i = start; i < end && i < static_cast<int>(v.size()); ++i) {
                    s += v[i];
                }
                return s;
            }
        
            float average(const std::vector<float>& v) {
                if (v.empty()) return 0.0f;
                float s = 0.0f;
                for (float x : v) s += x;
                return s / static_cast<float>(v.size());
            }
        
            // large block of repetitive switch / if logic
            int classify(int value) {
                switch (value % 10) {
                    case 0: return 100;
                    case 1: return 101;
                    case 2: return 102;
                    case 3: return 103;
                    case 4: return 104;
                    case 5: return 105;
                    case 6: return 106;
                    case 7: return 107;
                    case 8: return 108;
                    case 9: return 109;
                    default: return -1;
                }
            }
        
            int classify2(int value) {
                if (value < 0) return -1;
                if (value < 10) return 0;
                if (value < 20) return 1;
                if (value < 30) return 2;
                if (value < 40) return 3;
                if (value < 50) return 4;
                if (value < 60) return 5;
                if (value < 70) return 6;
                if (value < 80) return 7;
                if (value < 90) return 8;
                return 9;
            }
            #include <iostream>
            
            int add(int a, int b) {
                return a + b;
            }
            
            int main() {
                int x = 5;
                int y = 10;
                int result = add(x, y);
            
                for (int i = 0; i < 3; i++) {
                    result += i;
                }
            
                std::cout << result << '\n';
                return result;
            }
                //@prag LuauProton = { squB = eLineCheck } || can be "dLineCheck"
                #include <iostream>
                #include <vector>
                #include <string>
                #include <map>
                #include <memory>
                #include <algorithm>
                #include <cmath>
                #include <cassert>
            
                namespace TestNamespace {
            
                class BaseEntity {
                public:
                    BaseEntity() : id_(0), active_(true) {}
                    virtual ~BaseEntity() {}
            
                    virtual void update(float dt) = 0;
                    virtual void render() const = 0;
            
                    int getId() const { return id_; }
                    void setId(int id) { id_ = id; }
            
                    bool isActive() const { return active_; }
                    void setActive(bool active) { active_ = active; }
            
                protected:
                    int id_;
                    bool active_;
                };
            
                class Player : public BaseEntity {
                public:
                    Player() : health_(100.0f), speed_(5.0f), score_(0) {}
                    explicit Player(int id) : Player() { setId(id); }
            
                    void update(float dt) override {
                        if (!isActive()) return;
                        position_x_ += velocity_x_ * dt * speed_;
                        position_y_ += velocity_y_ * dt * speed_;
                        if (health_ <= 0.0f) {
                            setActive(false);
                        }
                    }
            
                    void render() const override {
                        if (!isActive()) return;
                        // placeholder render
                    }
            
                    void takeDamage(float amount) {
                        health_ -= amount;
                        if (health_ < 0.0f) health_ = 0.0f;
                    }
            
                    void heal(float amount) {
                        health_ += amount;
                        if (health_ > 100.0f) health_ = 100.0f;
                    }
            
                    void addScore(int points) { score_ += points; }
                    int getScore() const { return score_; }
                    float getHealth() const { return health_; }
            
                    void setVelocity(float vx, float vy) {
                        velocity_x_ = vx;
                        velocity_y_ = vy;
                    }
            
                private:
                    float health_;
                    float speed_;
                    int score_;
                    float position_x_ = 0.0f;
                    float position_y_ = 0.0f;
                    float velocity_x_ = 0.0f;
                    float velocity_y_ = 0.0f;
                };
            
                class Enemy : public BaseEntity {
                public:
                    enum class Type { Grunt, Elite, Boss };
            
                    Enemy() : type_(Type::Grunt), damage_(10.0f), health_(50.0f) {}
                    Enemy(Type t, float dmg, float hp) : type_(t), damage_(dmg), health_(hp) {}
            
                    void update(float dt) override {
                        if (!isActive()) return;
                        // simple AI placeholder
                        patrolTimer_ += dt;
                        if (patrolTimer_ > 2.0f) {
                            direction_ *= -1.0f;
                            patrolTimer_ = 0.0f;
                        }
                        position_x_ += direction_ * 2.0f * dt;
                    }
            
                    void render() const override {
                        if (!isActive()) return;
                    }
            
                    float getDamage() const { return damage_; }
                    Type getType() const { return type_; }
            
                    void takeDamage(float amount) {
                        health_ -= amount;
                        if (health_ <= 0.0f) {
                            setActive(false);
                        }
                    }
            
                private:
                    Type type_;
                    float damage_;
                    float health_;
                    float position_x_ = 0.0f;
                    float direction_ = 1.0f;
                    float patrolTimer_ = 0.0f;
                };
            
                class Projectile {
                public:
                    Projectile() : alive_(false) {}
                    Projectile(float x, float y, float vx, float vy, float dmg)
                        : pos_x_(x), pos_y_(y), vel_x_(vx), vel_y_(vy), damage_(dmg), alive_(true) {}
            
                    void update(float dt) {
                        if (!alive_) return;
                        pos_x_ += vel_x_ * dt;
                        pos_y_ += vel_y_ * dt;
                        lifetime_ += dt;
                        if (lifetime_ > 3.0f) alive_ = false;
                    }
            
                    bool isAlive() const { return alive_; }
                    float getDamage() const { return damage_; }
                    float getX() const { return pos_x_; }
                    float getY() const { return pos_y_; }
            
                    void kill() { alive_ = false; }
            
                private:
                    float pos_x_ = 0.0f;
                    float pos_y_ = 0.0f;
                    float vel_x_ = 0.0f;
                    float vel_y_ = 0.0f;
                    float damage_ = 0.0f;
                    float lifetime_ = 0.0f;
                    bool alive_ = false;
                };
            
                class GameWorld {
                public:
                    GameWorld() {
                        player_ = std::make_unique<Player>(1);
                        spawnEnemies(20);
                    }
            
                    void spawnEnemies(int count) {
                        for (int i = 0; i < count; ++i) {
                            Enemy::Type t = (i % 5 == 0) ? Enemy::Type::Elite : Enemy::Type::Grunt;
                            float dmg = (t == Enemy::Type::Elite) ? 25.0f : 10.0f;
                            float hp  = (t == Enemy::Type::Elite) ? 120.0f : 50.0f;
                            enemies_.emplace_back(t, dmg, hp);
                            enemies_.back().setId(100 + i);
                        }
                    }
            
                    void update(float dt) {
                        if (player_) player_->update(dt);
            
                        for (auto& e : enemies_) {
                            if (e.isActive()) e.update(dt);
                        }
            
                        for (auto& p : projectiles_) {
                            p.update(dt);
                        }
            
                        // simple collision placeholder
                        for (auto& p : projectiles_) {
                            if (!p.isAlive()) continue;
                            for (auto& e : enemies_) {
                                if (!e.isActive()) continue;
                                // pretend hit
                                if (std::abs(p.getX() - 0.0f) < 1.0f) {
                                    e.takeDamage(p.getDamage());
                                    p.kill();
                                    if (player_) player_->addScore(10);
                                }
                            }
                        }
            
                        // cleanup dead projectiles
                        projectiles_.erase(
                            std::remove_if(projectiles_.begin(), projectiles_.end(),
                                [](const Projectile& p) { return !p.isAlive(); }),
                            projectiles_.end());
                    }
            
                    void render() const {
                        if (player_) player_->render();
                        for (const auto& e : enemies_) {
                            if (e.isActive()) e.render();
                        }
                    }
            
                    void fireProjectile(float x, float y, float vx, float vy, float dmg) {
                        projectiles_.emplace_back(x, y, vx, vy, dmg);
                    }
            
                    Player* getPlayer() { return player_.get(); }
                    const std::vector<Enemy>& getEnemies() const { return enemies_; }
            
                private:
                    std::unique_ptr<Player> player_;
                    std::vector<Enemy> enemies_;
                    std::vector<Projectile> projectiles_;
                };
            
                // ---------- repetitive helper functions to pad line count ----------
            
                int add(int a, int b) { return a + b; }
                int sub(int a, int b) { return a - b; }
                int mul(int a, int b) { return a * b; }
                int div_safe(int a, int b) { return b != 0 ? a / b : 0; }
            
                float addf(float a, float b) { return a + b; }
                float subf(float a, float b) { return a - b; }
                float mulf(float a, float b) { return a * b; }
                float divf(float a, float b) { return b != 0.0f ? a / b : 0.0f; }
            
                bool isEven(int n) { return n % 2 == 0; }
                bool isOdd(int n) { return n % 2 != 0; }
                bool isPositive(int n) { return n > 0; }
                bool isNegative(int n) { return n < 0; }
            
                int clampInt(int v, int lo, int hi) {
                    if (v < lo) return lo;
                    if (v > hi) return hi;
                    return v;
                }
            
                float clampFloat(float v, float lo, float hi) {
                    if (v < lo) return lo;
                    if (v > hi) return hi;
                    return v;
                }
            
                int maxInt(int a, int b) { return a > b ? a : b; }
                int minInt(int a, int b) { return a < b ? a : b; }
                float maxFloat(float a, float b) { return a > b ? a : b; }
                float minFloat(float a, float b) { return a < b ? a : b; }
            
                // generate a lot of nearly identical utility functions
                int util001(int x) { return x * 1 + 1; }
                int util002(int x) { return x * 2 + 2; }
                int util003(int x) { return x * 3 + 3; }
                int util004(int x) { return x * 4 + 4; }
                int util005(int x) { return x * 5 + 5; }
                int util006(int x) { return x * 6 + 6; }
                int util007(int x) { return x * 7 + 7; }
                int util008(int x) { return x * 8 + 8; }
                int util009(int x) { return x * 9 + 9; }
                int util010(int x) { return x * 10 + 10; }
                int util011(int x) { return x * 11 + 11; }
                int util012(int x) { return x * 12 + 12; }
                int util013(int x) { return x * 13 + 13; }
                int util014(int x) { return x * 14 + 14; }
                int util015(int x) { return x * 15 + 15; }
                int util016(int x) { return x * 16 + 16; }
                int util017(int x) { return x * 17 + 17; }
                int util018(int x) { return x * 18 + 18; }
                int util019(int x) { return x * 19 + 19; }
                int util020(int x) { return x * 20 + 20; }
                int util021(int x) { return x * 21 + 21; }
                int util022(int x) { return x * 22 + 22; }
                int util023(int x) { return x * 23 + 23; }
                int util024(int x) { return x * 24 + 24; }
                int util025(int x) { return x * 25 + 25; }
                int util026(int x) { return x * 26 + 26; }
                int util027(int x) { return x * 27 + 27; }
                int util028(int x) { return x * 28 + 28; }
                int util029(int x) { return x * 29 + 29; }
                int util030(int x) { return x * 30 + 30; }
                int util031(int x) { return x * 31 + 31; }
                int util032(int x) { return x * 32 + 32; }
                int util033(int x) { return x * 33 + 33; }
                int util034(int x) { return x * 34 + 34; }
                int util035(int x) { return x * 35 + 35; }
                int util036(int x) { return x * 36 + 36; }
                int util037(int x) { return x * 37 + 37; }
                int util038(int x) { return x * 38 + 38; }
                int util039(int x) { return x * 39 + 39; }
                int util040(int x) { return x * 40 + 40; }
                int util041(int x) { return x * 41 + 41; }
                int util042(int x) { return x * 42 + 42; }
                int util043(int x) { return x * 43 + 43; }
                int util044(int x) { return x * 44 + 44; }
                int util045(int x) { return x * 45 + 45; }
                int util046(int x) { return x * 46 + 46; }
                int util047(int x) { return x * 47 + 47; }
                int util048(int x) { return x * 48 + 48; }
                int util049(int x) { return x * 49 + 49; }
                int util050(int x) { return x * 50 + 50; }
                int util051(int x) { return x * 51 + 51; }
                int util052(int x) { return x * 52 + 52; }
                int util053(int x) { return x * 53 + 53; }
                int util054(int x) { return x * 54 + 54; }
                int util055(int x) { return x * 55 + 55; }
                int util056(int x) { return x * 56 + 56; }
                int util057(int x) { return x * 57 + 57; }
                int util058(int x) { return x * 58 + 58; }
                int util059(int x) { return x * 59 + 59; }
                int util060(int x) { return x * 60 + 60; }
                int util061(int x) { return x * 61 + 61; }
                int util062(int x) { return x * 62 + 62; }
                int util063(int x) { return x * 63 + 63; }
                int util064(int x) { return x * 64 + 64; }
                int util065(int x) { return x * 65 + 65; }
                int util066(int x) { return x * 66 + 66; }
                int util067(int x) { return x * 67 + 67; }
                int util068(int x) { return x * 68 + 68; }
                int util069(int x) { return x * 69 + 69; }
                int util070(int x) { return x * 70 + 70; }
                int util071(int x) { return x * 71 + 71; }
                int util072(int x) { return x * 72 + 72; }
                int util073(int x) { return x * 73 + 73; }
                int util074(int x) { return x * 74 + 74; }
                int util075(int x) { return x * 75 + 75; }
                int util076(int x) { return x * 76 + 76; }
                int util077(int x) { return x * 77 + 77; }
                int util078(int x) { return x * 78 + 78; }
                int util079(int x) { return x * 79 + 79; }
                int util080(int x) { return x * 80 + 80; }
                int util081(int x) { return x * 81 + 81; }
                int util082(int x) { return x * 82 + 82; }
                int util083(int x) { return x * 83 + 83; }
                int util084(int x) { return x * 84 + 84; }
                int util085(int x) { return x * 85 + 85; }
                int util086(int x) { return x * 86 + 86; }
                int util087(int x) { return x * 87 + 87; }
                int util088(int x) { return x * 88 + 88; }
                int util089(int x) { return x * 89 + 89; }
                int util090(int x) { return x * 90 + 90; }
                int util091(int x) { return x * 91 + 91; }
                int util092(int x) { return x * 92 + 92; }
                int util093(int x) { return x * 93 + 93; }
                int util094(int x) { return x * 94 + 94; }
                int util095(int x) { return x * 95 + 95; }
                int util096(int x) { return x * 96 + 96; }
                int util097(int x) { return x * 97 + 97; }
                int util098(int x) { return x * 98 + 98; }
                int util099(int x) { return x * 99 + 99; }
                int util100(int x) { return x * 100 + 100; }
            
                // more padding with loops and conditionals
                void processBatch1(std::vector<int>& data) {
                    for (size_t i = 0; i < data.size(); ++i) {
                        if (data[i] < 0) data[i] = 0;
                        else if (data[i] > 1000) data[i] = 1000;
                        data[i] = data[i] * 2 + 1;
                    }
                }
            
                void processBatch2(std::vector<int>& data) {
                    for (size_t i = 0; i < data.size(); ++i) {
                        if (isEven(data[i])) data[i] += 10;
                        else data[i] -= 5;
                    }
                }
            
                void processBatch3(std::vector<float>& data) {
                    for (size_t i = 0; i < data.size(); ++i) {
                        data[i] = clampFloat(data[i], 0.0f, 1.0f);
                        data[i] = data[i] * data[i];
                    }
                }
            
                void fillSequence(std::vector<int>& out, int count) {
                    out.clear();
                    out.reserve(count);
                    for (int i = 0; i < count; ++i) {
                        out.push_back(i * 3 + 7);
                    }
                }
            
                int sumRange(const std::vector<int>& v, int start, int end) {
                    int s = 0;
                    for (int i = start; i < end && i < static_cast<int>(v.size()); ++i) {
                        s += v[i];
                    }
                    return s;
                }
            
                float average(const std::vector<float>& v) {
                    if (v.empty()) return 0.0f;
                    float s = 0.0f;
                    for (float x : v) s += x;
                    return s / static_cast<float>(v.size());
                }
            
                // large block of repetitive switch / if logic
                int classify(int value) {
                    switch (value % 10) {
                        case 0: return 100;
                        case 1: return 101;
                        case 2: return 102;
                        case 3: return 103;
                        case 4: return 104;
                        case 5: return 105;
                        case 6: return 106;
                        case 7: return 107;
                        case 8: return 108;
                        case 9: return 109;
                        default: return -1;
                    }
                }
            
                int classify2(int value) {
                    if (value < 0) return -1;
                    if (value < 10) return 0;
                    if (value < 20) return 1;
                    if (value < 30) return 2;
                    if (value < 40) return 3;
                    if (value < 50) return 4;
                    if (value < 60) return 5;
                    if (value < 70) return 6;
                    if (value < 80) return 7;
                    if (value < 90) return 8;
                    return 9;
                }
                #include <iostream>
                
                int add(int a, int b) {
                    return a + b;
                }
                
                int main() {
                    int x = 5;
                    int y = 10;
                    int result = add(x, y);
                
                    for (int i = 0; i < 3; i++) {
                        result += i;
                    }
                
                    std::cout << result << '\n';
                    return result;
                }
                    //@prag LuauProton = { squB = eLineCheck } || can be "dLineCheck"
                    #include <iostream>
                    #include <vector>
                    #include <string>
                    #include <map>
                    #include <memory>
                    #include <algorithm>
                    #include <cmath>
                    #include <cassert>
                
                    namespace TestNamespace {
                
                    class BaseEntity {
                    public:
                        BaseEntity() : id_(0), active_(true) {}
                        virtual ~BaseEntity() {}
                
                        virtual void update(float dt) = 0;
                        virtual void render() const = 0;
                
                        int getId() const { return id_; }
                        void setId(int id) { id_ = id; }
                
                        bool isActive() const { return active_; }
                        void setActive(bool active) { active_ = active; }
                
                    protected:
                        int id_;
                        bool active_;
                    };
                
                    class Player : public BaseEntity {
                    public:
                        Player() : health_(100.0f), speed_(5.0f), score_(0) {}
                        explicit Player(int id) : Player() { setId(id); }
                
                        void update(float dt) override {
                            if (!isActive()) return;
                            position_x_ += velocity_x_ * dt * speed_;
                            position_y_ += velocity_y_ * dt * speed_;
                            if (health_ <= 0.0f) {
                                setActive(false);
                            }
                        }
                
                        void render() const override {
                            if (!isActive()) return;
                            // placeholder render
                        }
                
                        void takeDamage(float amount) {
                            health_ -= amount;
                            if (health_ < 0.0f) health_ = 0.0f;
                        }
                
                        void heal(float amount) {
                            health_ += amount;
                            if (health_ > 100.0f) health_ = 100.0f;
                        }
                
                        void addScore(int points) { score_ += points; }
                        int getScore() const { return score_; }
                        float getHealth() const { return health_; }
                
                        void setVelocity(float vx, float vy) {
                            velocity_x_ = vx;
                            velocity_y_ = vy;
                        }
                
                    private:
                        float health_;
                        float speed_;
                        int score_;
                        float position_x_ = 0.0f;
                        float position_y_ = 0.0f;
                        float velocity_x_ = 0.0f;
                        float velocity_y_ = 0.0f;
                    };
                
                    class Enemy : public BaseEntity {
                    public:
                        enum class Type { Grunt, Elite, Boss };
                
                        Enemy() : type_(Type::Grunt), damage_(10.0f), health_(50.0f) {}
                        Enemy(Type t, float dmg, float hp) : type_(t), damage_(dmg), health_(hp) {}
                
                        void update(float dt) override {
                            if (!isActive()) return;
                            // simple AI placeholder
                            patrolTimer_ += dt;
                            if (patrolTimer_ > 2.0f) {
                                direction_ *= -1.0f;
                                patrolTimer_ = 0.0f;
                            }
                            position_x_ += direction_ * 2.0f * dt;
                        }
                
                        void render() const override {
                            if (!isActive()) return;
                        }
                
                        float getDamage() const { return damage_; }
                        Type getType() const { return type_; }
                
                        void takeDamage(float amount) {
                            health_ -= amount;
                            if (health_ <= 0.0f) {
                                setActive(false);
                            }
                        }
                
                    private:
                        Type type_;
                        float damage_;
                        float health_;
                        float position_x_ = 0.0f;
                        float direction_ = 1.0f;
                        float patrolTimer_ = 0.0f;
                    };
                
                    class Projectile {
                    public:
                        Projectile() : alive_(false) {}
                        Projectile(float x, float y, float vx, float vy, float dmg)
                            : pos_x_(x), pos_y_(y), vel_x_(vx), vel_y_(vy), damage_(dmg), alive_(true) {}
                
                        void update(float dt) {
                            if (!alive_) return;
                            pos_x_ += vel_x_ * dt;
                            pos_y_ += vel_y_ * dt;
                            lifetime_ += dt;
                            if (lifetime_ > 3.0f) alive_ = false;
                        }
                
                        bool isAlive() const { return alive_; }
                        float getDamage() const { return damage_; }
                        float getX() const { return pos_x_; }
                        float getY() const { return pos_y_; }
                
                        void kill() { alive_ = false; }
                
                    private:
                        float pos_x_ = 0.0f;
                        float pos_y_ = 0.0f;
                        float vel_x_ = 0.0f;
                        float vel_y_ = 0.0f;
                        float damage_ = 0.0f;
                        float lifetime_ = 0.0f;
                        bool alive_ = false;
                    };
                
                    class GameWorld {
                    public:
                        GameWorld() {
                            player_ = std::make_unique<Player>(1);
                            spawnEnemies(20);
                        }
                
                        void spawnEnemies(int count) {
                            for (int i = 0; i < count; ++i) {
                                Enemy::Type t = (i % 5 == 0) ? Enemy::Type::Elite : Enemy::Type::Grunt;
                                float dmg = (t == Enemy::Type::Elite) ? 25.0f : 10.0f;
                                float hp  = (t == Enemy::Type::Elite) ? 120.0f : 50.0f;
                                enemies_.emplace_back(t, dmg, hp);
                                enemies_.back().setId(100 + i);
                            }
                        }
                
                        void update(float dt) {
                            if (player_) player_->update(dt);
                
                            for (auto& e : enemies_) {
                                if (e.isActive()) e.update(dt);
                            }
                
                            for (auto& p : projectiles_) {
                                p.update(dt);
                            }
                
                            // simple collision placeholder
                            for (auto& p : projectiles_) {
                                if (!p.isAlive()) continue;
                                for (auto& e : enemies_) {
                                    if (!e.isActive()) continue;
                                    // pretend hit
                                    if (std::abs(p.getX() - 0.0f) < 1.0f) {
                                        e.takeDamage(p.getDamage());
                                        p.kill();
                                        if (player_) player_->addScore(10);
                                    }
                                }
                            }
                
                            // cleanup dead projectiles
                            projectiles_.erase(
                                std::remove_if(projectiles_.begin(), projectiles_.end(),
                                    [](const Projectile& p) { return !p.isAlive(); }),
                                projectiles_.end());
                        }
                
                        void render() const {
                            if (player_) player_->render();
                            for (const auto& e : enemies_) {
                                if (e.isActive()) e.render();
                            }
                        }
                
                        void fireProjectile(float x, float y, float vx, float vy, float dmg) {
                            projectiles_.emplace_back(x, y, vx, vy, dmg);
                        }
                
                        Player* getPlayer() { return player_.get(); }
                        const std::vector<Enemy>& getEnemies() const { return enemies_; }
                
                    private:
                        std::unique_ptr<Player> player_;
                        std::vector<Enemy> enemies_;
                        std::vector<Projectile> projectiles_;
                    };
                
                    // ---------- repetitive helper functions to pad line count ----------
                
                    int add(int a, int b) { return a + b; }
                    int sub(int a, int b) { return a - b; }
                    int mul(int a, int b) { return a * b; }
                    int div_safe(int a, int b) { return b != 0 ? a / b : 0; }
                
                    float addf(float a, float b) { return a + b; }
                    float subf(float a, float b) { return a - b; }
                    float mulf(float a, float b) { return a * b; }
                    float divf(float a, float b) { return b != 0.0f ? a / b : 0.0f; }
                
                    bool isEven(int n) { return n % 2 == 0; }
                    bool isOdd(int n) { return n % 2 != 0; }
                    bool isPositive(int n) { return n > 0; }
                    bool isNegative(int n) { return n < 0; }
                
                    int clampInt(int v, int lo, int hi) {
                        if (v < lo) return lo;
                        if (v > hi) return hi;
                        return v;
                    }
                
                    float clampFloat(float v, float lo, float hi) {
                        if (v < lo) return lo;
                        if (v > hi) return hi;
                        return v;
                    }
                
                    int maxInt(int a, int b) { return a > b ? a : b; }
                    int minInt(int a, int b) { return a < b ? a : b; }
                    float maxFloat(float a, float b) { return a > b ? a : b; }
                    float minFloat(float a, float b) { return a < b ? a : b; }
                
                    // generate a lot of nearly identical utility functions
                    int util001(int x) { return x * 1 + 1; }
                    int util002(int x) { return x * 2 + 2; }
                    int util003(int x) { return x * 3 + 3; }
                    int util004(int x) { return x * 4 + 4; }
                    int util005(int x) { return x * 5 + 5; }
                    int util006(int x) { return x * 6 + 6; }
                    int util007(int x) { return x * 7 + 7; }
                    int util008(int x) { return x * 8 + 8; }
                    int util009(int x) { return x * 9 + 9; }
                    int util010(int x) { return x * 10 + 10; }
                    int util011(int x) { return x * 11 + 11; }
                    int util012(int x) { return x * 12 + 12; }
                    int util013(int x) { return x * 13 + 13; }
                    int util014(int x) { return x * 14 + 14; }
                    int util015(int x) { return x * 15 + 15; }
                    int util016(int x) { return x * 16 + 16; }
                    int util017(int x) { return x * 17 + 17; }
                    int util018(int x) { return x * 18 + 18; }
                    int util019(int x) { return x * 19 + 19; }
                    int util020(int x) { return x * 20 + 20; }
                    int util021(int x) { return x * 21 + 21; }
                    int util022(int x) { return x * 22 + 22; }
                    int util023(int x) { return x * 23 + 23; }
                    int util024(int x) { return x * 24 + 24; }
                    int util025(int x) { return x * 25 + 25; }
                    int util026(int x) { return x * 26 + 26; }
                    int util027(int x) { return x * 27 + 27; }
                    int util028(int x) { return x * 28 + 28; }
                    int util029(int x) { return x * 29 + 29; }
                    int util030(int x) { return x * 30 + 30; }
                    int util031(int x) { return x * 31 + 31; }
                    int util032(int x) { return x * 32 + 32; }
                    int util033(int x) { return x * 33 + 33; }
                    int util034(int x) { return x * 34 + 34; }
                    int util035(int x) { return x * 35 + 35; }
                    int util036(int x) { return x * 36 + 36; }
                    int util037(int x) { return x * 37 + 37; }
                    int util038(int x) { return x * 38 + 38; }
                    int util039(int x) { return x * 39 + 39; }
                    int util040(int x) { return x * 40 + 40; }
                    int util041(int x) { return x * 41 + 41; }
                    int util042(int x) { return x * 42 + 42; }
                    int util043(int x) { return x * 43 + 43; }
                    int util044(int x) { return x * 44 + 44; }
                    int util045(int x) { return x * 45 + 45; }
                    int util046(int x) { return x * 46 + 46; }
                    int util047(int x) { return x * 47 + 47; }
                    int util048(int x) { return x * 48 + 48; }
                    int util049(int x) { return x * 49 + 49; }
                    int util050(int x) { return x * 50 + 50; }
                    int util051(int x) { return x * 51 + 51; }
                    int util052(int x) { return x * 52 + 52; }
                    int util053(int x) { return x * 53 + 53; }
                    int util054(int x) { return x * 54 + 54; }
                    int util055(int x) { return x * 55 + 55; }
                    int util056(int x) { return x * 56 + 56; }
                    int util057(int x) { return x * 57 + 57; }
                    int util058(int x) { return x * 58 + 58; }
                    int util059(int x) { return x * 59 + 59; }
                    int util060(int x) { return x * 60 + 60; }
                    int util061(int x) { return x * 61 + 61; }
                    int util062(int x) { return x * 62 + 62; }
                    int util063(int x) { return x * 63 + 63; }
                    int util064(int x) { return x * 64 + 64; }
                    int util065(int x) { return x * 65 + 65; }
                    int util066(int x) { return x * 66 + 66; }
                    int util067(int x) { return x * 67 + 67; }
                    int util068(int x) { return x * 68 + 68; }
                    int util069(int x) { return x * 69 + 69; }
                    int util070(int x) { return x * 70 + 70; }
                    int util071(int x) { return x * 71 + 71; }
                    int util072(int x) { return x * 72 + 72; }
                    int util073(int x) { return x * 73 + 73; }
                    int util074(int x) { return x * 74 + 74; }
                    int util075(int x) { return x * 75 + 75; }
                    int util076(int x) { return x * 76 + 76; }
                    int util077(int x) { return x * 77 + 77; }
                    int util078(int x) { return x * 78 + 78; }
                    int util079(int x) { return x * 79 + 79; }
                    int util080(int x) { return x * 80 + 80; }
                    int util081(int x) { return x * 81 + 81; }
                    int util082(int x) { return x * 82 + 82; }
                    int util083(int x) { return x * 83 + 83; }
                    int util084(int x) { return x * 84 + 84; }
                    int util085(int x) { return x * 85 + 85; }
                    int util086(int x) { return x * 86 + 86; }
                    int util087(int x) { return x * 87 + 87; }
                    int util088(int x) { return x * 88 + 88; }
                    int util089(int x) { return x * 89 + 89; }
                    int util090(int x) { return x * 90 + 90; }
                    int util091(int x) { return x * 91 + 91; }
                    int util092(int x) { return x * 92 + 92; }
                    int util093(int x) { return x * 93 + 93; }
                    int util094(int x) { return x * 94 + 94; }
                    int util095(int x) { return x * 95 + 95; }
                    int util096(int x) { return x * 96 + 96; }
                    int util097(int x) { return x * 97 + 97; }
                    int util098(int x) { return x * 98 + 98; }
                    int util099(int x) { return x * 99 + 99; }
                    int util100(int x) { return x * 100 + 100; }
                
                    // more padding with loops and conditionals
                    void processBatch1(std::vector<int>& data) {
                        for (size_t i = 0; i < data.size(); ++i) {
                            if (data[i] < 0) data[i] = 0;
                            else if (data[i] > 1000) data[i] = 1000;
                            data[i] = data[i] * 2 + 1;
                        }
                    }
                
                    void processBatch2(std::vector<int>& data) {
                        for (size_t i = 0; i < data.size(); ++i) {
                            if (isEven(data[i])) data[i] += 10;
                            else data[i] -= 5;
                        }
                    }
                
                    void processBatch3(std::vector<float>& data) {
                        for (size_t i = 0; i < data.size(); ++i) {
                            data[i] = clampFloat(data[i], 0.0f, 1.0f);
                            data[i] = data[i] * data[i];
                        }
                    }
                
                    void fillSequence(std::vector<int>& out, int count) {
                        out.clear();
                        out.reserve(count);
                        for (int i = 0; i < count; ++i) {
                            out.push_back(i * 3 + 7);
                        }
                    }
                
                    int sumRange(const std::vector<int>& v, int start, int end) {
                        int s = 0;
                        for (int i = start; i < end && i < static_cast<int>(v.size()); ++i) {
                            s += v[i];
                        }
                        return s;
                    }
                
                    float average(const std::vector<float>& v) {
                        if (v.empty()) return 0.0f;
                        float s = 0.0f;
                        for (float x : v) s += x;
                        return s / static_cast<float>(v.size());
                    }
                
                    // large block of repetitive switch / if logic
                    int classify(int value) {
                        switch (value % 10) {
                            case 0: return 100;
                            case 1: return 101;
                            case 2: return 102;
                            case 3: return 103;
                            case 4: return 104;
                            case 5: return 105;
                            case 6: return 106;
                            case 7: return 107;
                            case 8: return 108;
                            case 9: return 109;
                            default: return -1;
                        }
                    }
                
                    int classify2(int value) {
                        if (value < 0) return -1;
                        if (value < 10) return 0;
                        if (value < 20) return 1;
                        if (value < 30) return 2;
                        if (value < 40) return 3;
                        if (value < 50) return 4;
                        if (value < 60) return 5;
                        if (value < 70) return 6;
                        if (value < 80) return 7;
                        if (value < 90) return 8;
                        return 9;
                    }
                    #include <iostream>
                    
                    int add(int a, int b) {
                        return a + b;
                    }
                    
                    int main() {
                        int x = 5;
                        int y = 10;
                        int result = add(x, y);
                    
                        for (int i = 0; i < 3; i++) {
                            result += i;
                        }
                    
                        std::cout << result << '\n';
                        return result;
                    }
                        //@prag LuauProton = { squB = eLineCheck } || can be "dLineCheck"
                        #include <iostream>
                        #include <vector>
                        #include <string>
                        #include <map>
                        #include <memory>
                        #include <algorithm>
                        #include <cmath>
                        #include <cassert>
                    
                        namespace TestNamespace {
                    
                        class BaseEntity {
                        public:
                            BaseEntity() : id_(0), active_(true) {}
                            virtual ~BaseEntity() {}
                    
                            virtual void update(float dt) = 0;
                            virtual void render() const = 0;
                    
                            int getId() const { return id_; }
                            void setId(int id) { id_ = id; }
                    
                            bool isActive() const { return active_; }
                            void setActive(bool active) { active_ = active; }
                    
                        protected:
                            int id_;
                            bool active_;
                        };
                    
                        class Player : public BaseEntity {
                        public:
                            Player() : health_(100.0f), speed_(5.0f), score_(0) {}
                            explicit Player(int id) : Player() { setId(id); }
                    
                            void update(float dt) override {
                                if (!isActive()) return;
                                position_x_ += velocity_x_ * dt * speed_;
                                position_y_ += velocity_y_ * dt * speed_;
                                if (health_ <= 0.0f) {
                                    setActive(false);
                                }
                            }
                    
                            void render() const override {
                                if (!isActive()) return;
                                // placeholder render
                            }
                    
                            void takeDamage(float amount) {
                                health_ -= amount;
                                if (health_ < 0.0f) health_ = 0.0f;
                            }
                    
                            void heal(float amount) {
                                health_ += amount;
                                if (health_ > 100.0f) health_ = 100.0f;
                            }
                    
                            void addScore(int points) { score_ += points; }
                            int getScore() const { return score_; }
                            float getHealth() const { return health_; }
                    
                            void setVelocity(float vx, float vy) {
                                velocity_x_ = vx;
                                velocity_y_ = vy;
                            }
                    
                        private:
                            float health_;
                            float speed_;
                            int score_;
                            float position_x_ = 0.0f;
                            float position_y_ = 0.0f;
                            float velocity_x_ = 0.0f;
                            float velocity_y_ = 0.0f;
                        };
                    
                        class Enemy : public BaseEntity {
                        public:
                            enum class Type { Grunt, Elite, Boss };
                    
                            Enemy() : type_(Type::Grunt), damage_(10.0f), health_(50.0f) {}
                            Enemy(Type t, float dmg, float hp) : type_(t), damage_(dmg), health_(hp) {}
                    
                            void update(float dt) override {
                                if (!isActive()) return;
                                // simple AI placeholder
                                patrolTimer_ += dt;
                                if (patrolTimer_ > 2.0f) {
                                    direction_ *= -1.0f;
                                    patrolTimer_ = 0.0f;
                                }
                                position_x_ += direction_ * 2.0f * dt;
                            }
                    
                            void render() const override {
                                if (!isActive()) return;
                            }
                    
                            float getDamage() const { return damage_; }
                            Type getType() const { return type_; }
                    
                            void takeDamage(float amount) {
                                health_ -= amount;
                                if (health_ <= 0.0f) {
                                    setActive(false);
                                }
                            }
                    
                        private:
                            Type type_;
                            float damage_;
                            float health_;
                            float position_x_ = 0.0f;
                            float direction_ = 1.0f;
                            float patrolTimer_ = 0.0f;
                        };
                    
                        class Projectile {
                        public:
                            Projectile() : alive_(false) {}
                            Projectile(float x, float y, float vx, float vy, float dmg)
                                : pos_x_(x), pos_y_(y), vel_x_(vx), vel_y_(vy), damage_(dmg), alive_(true) {}
                    
                            void update(float dt) {
                                if (!alive_) return;
                                pos_x_ += vel_x_ * dt;
                                pos_y_ += vel_y_ * dt;
                                lifetime_ += dt;
                                if (lifetime_ > 3.0f) alive_ = false;
                            }
                    
                            bool isAlive() const { return alive_; }
                            float getDamage() const { return damage_; }
                            float getX() const { return pos_x_; }
                            float getY() const { return pos_y_; }
                    
                            void kill() { alive_ = false; }
                    
                        private:
                            float pos_x_ = 0.0f;
                            float pos_y_ = 0.0f;
                            float vel_x_ = 0.0f;
                            float vel_y_ = 0.0f;
                            float damage_ = 0.0f;
                            float lifetime_ = 0.0f;
                            bool alive_ = false;
                        };
                    
                        class GameWorld {
                        public:
                            GameWorld() {
                                player_ = std::make_unique<Player>(1);
                                spawnEnemies(20);
                            }
                    
                            void spawnEnemies(int count) {
                                for (int i = 0; i < count; ++i) {
                                    Enemy::Type t = (i % 5 == 0) ? Enemy::Type::Elite : Enemy::Type::Grunt;
                                    float dmg = (t == Enemy::Type::Elite) ? 25.0f : 10.0f;
                                    float hp  = (t == Enemy::Type::Elite) ? 120.0f : 50.0f;
                                    enemies_.emplace_back(t, dmg, hp);
                                    enemies_.back().setId(100 + i);
                                }
                            }
                    
                            void update(float dt) {
                                if (player_) player_->update(dt);
                    
                                for (auto& e : enemies_) {
                                    if (e.isActive()) e.update(dt);
                                }
                    
                                for (auto& p : projectiles_) {
                                    p.update(dt);
                                }
                    
                                // simple collision placeholder
                                for (auto& p : projectiles_) {
                                    if (!p.isAlive()) continue;
                                    for (auto& e : enemies_) {
                                        if (!e.isActive()) continue;
                                        // pretend hit
                                        if (std::abs(p.getX() - 0.0f) < 1.0f) {
                                            e.takeDamage(p.getDamage());
                                            p.kill();
                                            if (player_) player_->addScore(10);
                                        }
                                    }
                                }
                    
                                // cleanup dead projectiles
                                projectiles_.erase(
                                    std::remove_if(projectiles_.begin(), projectiles_.end(),
                                        [](const Projectile& p) { return !p.isAlive(); }),
                                    projectiles_.end());
                            }
                    
                            void render() const {
                                if (player_) player_->render();
                                for (const auto& e : enemies_) {
                                    if (e.isActive()) e.render();
                                }
                            }
                    
                            void fireProjectile(float x, float y, float vx, float vy, float dmg) {
                                projectiles_.emplace_back(x, y, vx, vy, dmg);
                            }
                    
                            Player* getPlayer() { return player_.get(); }
                            const std::vector<Enemy>& getEnemies() const { return enemies_; }
                    
                        private:
                            std::unique_ptr<Player> player_;
                            std::vector<Enemy> enemies_;
                            std::vector<Projectile> projectiles_;
                        };
                    
                        // ---------- repetitive helper functions to pad line count ----------
                    
                        int add(int a, int b) { return a + b; }
                        int sub(int a, int b) { return a - b; }
                        int mul(int a, int b) { return a * b; }
                        int div_safe(int a, int b) { return b != 0 ? a / b : 0; }
                    
                        float addf(float a, float b) { return a + b; }
                        float subf(float a, float b) { return a - b; }
                        float mulf(float a, float b) { return a * b; }
                        float divf(float a, float b) { return b != 0.0f ? a / b : 0.0f; }
                    
                        bool isEven(int n) { return n % 2 == 0; }
                        bool isOdd(int n) { return n % 2 != 0; }
                        bool isPositive(int n) { return n > 0; }
                        bool isNegative(int n) { return n < 0; }
                    
                        int clampInt(int v, int lo, int hi) {
                            if (v < lo) return lo;
                            if (v > hi) return hi;
                            return v;
                        }
                    
                        float clampFloat(float v, float lo, float hi) {
                            if (v < lo) return lo;
                            if (v > hi) return hi;
                            return v;
                        }
                    
                        int maxInt(int a, int b) { return a > b ? a : b; }
                        int minInt(int a, int b) { return a < b ? a : b; }
                        float maxFloat(float a, float b) { return a > b ? a : b; }
                        float minFloat(float a, float b) { return a < b ? a : b; }
                    
                        // generate a lot of nearly identical utility functions
                        int util001(int x) { return x * 1 + 1; }
                        int util002(int x) { return x * 2 + 2; }
                        int util003(int x) { return x * 3 + 3; }
                        int util004(int x) { return x * 4 + 4; }
                        int util005(int x) { return x * 5 + 5; }
                        int util006(int x) { return x * 6 + 6; }
                        int util007(int x) { return x * 7 + 7; }
                        int util008(int x) { return x * 8 + 8; }
                        int util009(int x) { return x * 9 + 9; }
                        int util010(int x) { return x * 10 + 10; }
                        int util011(int x) { return x * 11 + 11; }
                        int util012(int x) { return x * 12 + 12; }
                        int util013(int x) { return x * 13 + 13; }
                        int util014(int x) { return x * 14 + 14; }
                        int util015(int x) { return x * 15 + 15; }
                        int util016(int x) { return x * 16 + 16; }
                        int util017(int x) { return x * 17 + 17; }
                        int util018(int x) { return x * 18 + 18; }
                        int util019(int x) { return x * 19 + 19; }
                        int util020(int x) { return x * 20 + 20; }
                        int util021(int x) { return x * 21 + 21; }
                        int util022(int x) { return x * 22 + 22; }
                        int util023(int x) { return x * 23 + 23; }
                        int util024(int x) { return x * 24 + 24; }
                        int util025(int x) { return x * 25 + 25; }
                        int util026(int x) { return x * 26 + 26; }
                        int util027(int x) { return x * 27 + 27; }
                        int util028(int x) { return x * 28 + 28; }
                        int util029(int x) { return x * 29 + 29; }
                        int util030(int x) { return x * 30 + 30; }
                        int util031(int x) { return x * 31 + 31; }
                        int util032(int x) { return x * 32 + 32; }
                        int util033(int x) { return x * 33 + 33; }
                        int util034(int x) { return x * 34 + 34; }
                        int util035(int x) { return x * 35 + 35; }
                        int util036(int x) { return x * 36 + 36; }
                        int util037(int x) { return x * 37 + 37; }
                        int util038(int x) { return x * 38 + 38; }
                        int util039(int x) { return x * 39 + 39; }
                        int util040(int x) { return x * 40 + 40; }
                        int util041(int x) { return x * 41 + 41; }
                        int util042(int x) { return x * 42 + 42; }
                        int util043(int x) { return x * 43 + 43; }
                        int util044(int x) { return x * 44 + 44; }
                        int util045(int x) { return x * 45 + 45; }
                        int util046(int x) { return x * 46 + 46; }
                        int util047(int x) { return x * 47 + 47; }
                        int util048(int x) { return x * 48 + 48; }
                        int util049(int x) { return x * 49 + 49; }
                        int util050(int x) { return x * 50 + 50; }
                        int util051(int x) { return x * 51 + 51; }
                        int util052(int x) { return x * 52 + 52; }
                        int util053(int x) { return x * 53 + 53; }
                        int util054(int x) { return x * 54 + 54; }
                        int util055(int x) { return x * 55 + 55; }
                        int util056(int x) { return x * 56 + 56; }
                        int util057(int x) { return x * 57 + 57; }
                        int util058(int x) { return x * 58 + 58; }
                        int util059(int x) { return x * 59 + 59; }
                        int util060(int x) { return x * 60 + 60; }
                        int util061(int x) { return x * 61 + 61; }
                        int util062(int x) { return x * 62 + 62; }
                        int util063(int x) { return x * 63 + 63; }
                        int util064(int x) { return x * 64 + 64; }
                        int util065(int x) { return x * 65 + 65; }
                        int util066(int x) { return x * 66 + 66; }
                        int util067(int x) { return x * 67 + 67; }
                        int util068(int x) { return x * 68 + 68; }
                        int util069(int x) { return x * 69 + 69; }
                        int util070(int x) { return x * 70 + 70; }
                        int util071(int x) { return x * 71 + 71; }
                        int util072(int x) { return x * 72 + 72; }
                        int util073(int x) { return x * 73 + 73; }
                        int util074(int x) { return x * 74 + 74; }
                        int util075(int x) { return x * 75 + 75; }
                        int util076(int x) { return x * 76 + 76; }
                        int util077(int x) { return x * 77 + 77; }
                        int util078(int x) { return x * 78 + 78; }
                        int util079(int x) { return x * 79 + 79; }
                        int util080(int x) { return x * 80 + 80; }
                        int util081(int x) { return x * 81 + 81; }
                        int util082(int x) { return x * 82 + 82; }
                        int util083(int x) { return x * 83 + 83; }
                        int util084(int x) { return x * 84 + 84; }
                        int util085(int x) { return x * 85 + 85; }
                        int util086(int x) { return x * 86 + 86; }
                        int util087(int x) { return x * 87 + 87; }
                        int util088(int x) { return x * 88 + 88; }
                        int util089(int x) { return x * 89 + 89; }
                        int util090(int x) { return x * 90 + 90; }
                        int util091(int x) { return x * 91 + 91; }
                        int util092(int x) { return x * 92 + 92; }
                        int util093(int x) { return x * 93 + 93; }
                        int util094(int x) { return x * 94 + 94; }
                        int util095(int x) { return x * 95 + 95; }
                        int util096(int x) { return x * 96 + 96; }
                        int util097(int x) { return x * 97 + 97; }
                        int util098(int x) { return x * 98 + 98; }
                        int util099(int x) { return x * 99 + 99; }
                        int util100(int x) { return x * 100 + 100; }
                    
                        // more padding with loops and conditionals
                        void processBatch1(std::vector<int>& data) {
                            for (size_t i = 0; i < data.size(); ++i) {
                                if (data[i] < 0) data[i] = 0;
                                else if (data[i] > 1000) data[i] = 1000;
                                data[i] = data[i] * 2 + 1;
                            }
                        }
                    
                        void processBatch2(std::vector<int>& data) {
                            for (size_t i = 0; i < data.size(); ++i) {
                                if (isEven(data[i])) data[i] += 10;
                                else data[i] -= 5;
                            }
                        }
                    
                        void processBatch3(std::vector<float>& data) {
                            for (size_t i = 0; i < data.size(); ++i) {
                                data[i] = clampFloat(data[i], 0.0f, 1.0f);
                                data[i] = data[i] * data[i];
                            }
                        }
                    
                        void fillSequence(std::vector<int>& out, int count) {
                            out.clear();
                            out.reserve(count);
                            for (int i = 0; i < count; ++i) {
                                out.push_back(i * 3 + 7);
                            }
                        }
                    
                        int sumRange(const std::vector<int>& v, int start, int end) {
                            int s = 0;
                            for (int i = start; i < end && i < static_cast<int>(v.size()); ++i) {
                                s += v[i];
                            }
                            return s;
                        }
                    
                        float average(const std::vector<float>& v) {
                            if (v.empty()) return 0.0f;
                            float s = 0.0f;
                            for (float x : v) s += x;
                            return s / static_cast<float>(v.size());
                        }
                    
                        // large block of repetitive switch / if logic
                        int classify(int value) {
                            switch (value % 10) {
                                case 0: return 100;
                                case 1: return 101;
                                case 2: return 102;
                                case 3: return 103;
                                case 4: return 104;
                                case 5: return 105;
                                case 6: return 106;
                                case 7: return 107;
                                case 8: return 108;
                                case 9: return 109;
                                default: return -1;
                            }
                        }
                    
                        int classify2(int value) {
                            if (value < 0) return -1;
                            if (value < 10) return 0;
                            if (value < 20) return 1;
                            if (value < 30) return 2;
                            if (value < 40) return 3;
                            if (value < 50) return 4;
                            if (value < 60) return 5;
                            if (value < 70) return 6;
                            if (value < 80) return 7;
                            if (value < 90) return 8;
                            return 9;
                        }
                        #include <iostream>
                        
                        int add(int a, int b) {
                            return a + b;
                        }
                        
                        int main() {
                            int x = 5;
                            int y = 10;
                            int result = add(x, y);
                        
                            for (int i = 0; i < 3; i++) {
                                result += i;
                            }
                        
                            std::cout << result << '\n';
                            return result;
                        }
                            //@prag LuauProton = { squB = eLineCheck } || can be "dLineCheck"
                            #include <iostream>
                            #include <vector>
                            #include <string>
                            #include <map>
                            #include <memory>
                            #include <algorithm>
                            #include <cmath>
                            #include <cassert>
                        
                            namespace TestNamespace {
                        
                            class BaseEntity {
                            public:
                                BaseEntity() : id_(0), active_(true) {}
                                virtual ~BaseEntity() {}
                        
                                virtual void update(float dt) = 0;
                                virtual void render() const = 0;
                        
                                int getId() const { return id_; }
                                void setId(int id) { id_ = id; }
                        
                                bool isActive() const { return active_; }
                                void setActive(bool active) { active_ = active; }
                        
                            protected:
                                int id_;
                                bool active_;
                            };
                        
                            class Player : public BaseEntity {
                            public:
                                Player() : health_(100.0f), speed_(5.0f), score_(0) {}
                                explicit Player(int id) : Player() { setId(id); }
                        
                                void update(float dt) override {
                                    if (!isActive()) return;
                                    position_x_ += velocity_x_ * dt * speed_;
                                    position_y_ += velocity_y_ * dt * speed_;
                                    if (health_ <= 0.0f) {
                                        setActive(false);
                                    }
                                }
                        
                                void render() const override {
                                    if (!isActive()) return;
                                    // placeholder render
                                }
                        
                                void takeDamage(float amount) {
                                    health_ -= amount;
                                    if (health_ < 0.0f) health_ = 0.0f;
                                }
                        
                                void heal(float amount) {
                                    health_ += amount;
                                    if (health_ > 100.0f) health_ = 100.0f;
                                }
                        
                                void addScore(int points) { score_ += points; }
                                int getScore() const { return score_; }
                                float getHealth() const { return health_; }
                        
                                void setVelocity(float vx, float vy) {
                                    velocity_x_ = vx;
                                    velocity_y_ = vy;
                                }
                        
                            private:
                                float health_;
                                float speed_;
                                int score_;
                                float position_x_ = 0.0f;
                                float position_y_ = 0.0f;
                                float velocity_x_ = 0.0f;
                                float velocity_y_ = 0.0f;
                            };
                        
                            class Enemy : public BaseEntity {
                            public:
                                enum class Type { Grunt, Elite, Boss };
                        
                                Enemy() : type_(Type::Grunt), damage_(10.0f), health_(50.0f) {}
                                Enemy(Type t, float dmg, float hp) : type_(t), damage_(dmg), health_(hp) {}
                        
                                void update(float dt) override {
                                    if (!isActive()) return;
                                    // simple AI placeholder
                                    patrolTimer_ += dt;
                                    if (patrolTimer_ > 2.0f) {
                                        direction_ *= -1.0f;
                                        patrolTimer_ = 0.0f;
                                    }
                                    position_x_ += direction_ * 2.0f * dt;
                                }
                        
                                void render() const override {
                                    if (!isActive()) return;
                                }
                        
                                float getDamage() const { return damage_; }
                                Type getType() const { return type_; }
                        
                                void takeDamage(float amount) {
                                    health_ -= amount;
                                    if (health_ <= 0.0f) {
                                        setActive(false);
                                    }
                                }
                        
                            private:
                                Type type_;
                                float damage_;
                                float health_;
                                float position_x_ = 0.0f;
                                float direction_ = 1.0f;
                                float patrolTimer_ = 0.0f;
                            };
                        
                            class Projectile {
                            public:
                                Projectile() : alive_(false) {}
                                Projectile(float x, float y, float vx, float vy, float dmg)
                                    : pos_x_(x), pos_y_(y), vel_x_(vx), vel_y_(vy), damage_(dmg), alive_(true) {}
                        
                                void update(float dt) {
                                    if (!alive_) return;
                                    pos_x_ += vel_x_ * dt;
                                    pos_y_ += vel_y_ * dt;
                                    lifetime_ += dt;
                                    if (lifetime_ > 3.0f) alive_ = false;
                                }
                        
                                bool isAlive() const { return alive_; }
                                float getDamage() const { return damage_; }
                                float getX() const { return pos_x_; }
                                float getY() const { return pos_y_; }
                        
                                void kill() { alive_ = false; }
                        
                            private:
                                float pos_x_ = 0.0f;
                                float pos_y_ = 0.0f;
                                float vel_x_ = 0.0f;
                                float vel_y_ = 0.0f;
                                float damage_ = 0.0f;
                                float lifetime_ = 0.0f;
                                bool alive_ = false;
                            };
                        
                            class GameWorld {
                            public:
                                GameWorld() {
                                    player_ = std::make_unique<Player>(1);
                                    spawnEnemies(20);
                                }
                        
                                void spawnEnemies(int count) {
                                    for (int i = 0; i < count; ++i) {
                                        Enemy::Type t = (i % 5 == 0) ? Enemy::Type::Elite : Enemy::Type::Grunt;
                                        float dmg = (t == Enemy::Type::Elite) ? 25.0f : 10.0f;
                                        float hp  = (t == Enemy::Type::Elite) ? 120.0f : 50.0f;
                                        enemies_.emplace_back(t, dmg, hp);
                                        enemies_.back().setId(100 + i);
                                    }
                                }
                        
                                void update(float dt) {
                                    if (player_) player_->update(dt);
                        
                                    for (auto& e : enemies_) {
                                        if (e.isActive()) e.update(dt);
                                    }
                        
                                    for (auto& p : projectiles_) {
                                        p.update(dt);
                                    }
                        
                                    // simple collision placeholder
                                    for (auto& p : projectiles_) {
                                        if (!p.isAlive()) continue;
                                        for (auto& e : enemies_) {
                                            if (!e.isActive()) continue;
                                            // pretend hit
                                            if (std::abs(p.getX() - 0.0f) < 1.0f) {
                                                e.takeDamage(p.getDamage());
                                                p.kill();
                                                if (player_) player_->addScore(10);
                                            }
                                        }
                                    }
                        
                                    // cleanup dead projectiles
                                    projectiles_.erase(
                                        std::remove_if(projectiles_.begin(), projectiles_.end(),
                                            [](const Projectile& p) { return !p.isAlive(); }),
                                        projectiles_.end());
                                }
                        
                                void render() const {
                                    if (player_) player_->render();
                                    for (const auto& e : enemies_) {
                                        if (e.isActive()) e.render();
                                    }
                                }
                        
                                void fireProjectile(float x, float y, float vx, float vy, float dmg) {
                                    projectiles_.emplace_back(x, y, vx, vy, dmg);
                                }
                        
                                Player* getPlayer() { return player_.get(); }
                                const std::vector<Enemy>& getEnemies() const { return enemies_; }
                        
                            private:
                                std::unique_ptr<Player> player_;
                                std::vector<Enemy> enemies_;
                                std::vector<Projectile> projectiles_;
                            };
                        
                            // ---------- repetitive helper functions to pad line count ----------
                        
                            int add(int a, int b) { return a + b; }
                            int sub(int a, int b) { return a - b; }
                            int mul(int a, int b) { return a * b; }
                            int div_safe(int a, int b) { return b != 0 ? a / b : 0; }
                        
                            float addf(float a, float b) { return a + b; }
                            float subf(float a, float b) { return a - b; }
                            float mulf(float a, float b) { return a * b; }
                            float divf(float a, float b) { return b != 0.0f ? a / b : 0.0f; }
                        
                            bool isEven(int n) { return n % 2 == 0; }
                            bool isOdd(int n) { return n % 2 != 0; }
                            bool isPositive(int n) { return n > 0; }
                            bool isNegative(int n) { return n < 0; }
                        
                            int clampInt(int v, int lo, int hi) {
                                if (v < lo) return lo;
                                if (v > hi) return hi;
                                return v;
                            }
                        
                            float clampFloat(float v, float lo, float hi) {
                                if (v < lo) return lo;
                                if (v > hi) return hi;
                                return v;
                            }
                        
                            int maxInt(int a, int b) { return a > b ? a : b; }
                            int minInt(int a, int b) { return a < b ? a : b; }
                            float maxFloat(float a, float b) { return a > b ? a : b; }
                            float minFloat(float a, float b) { return a < b ? a : b; }
                        
                            // generate a lot of nearly identical utility functions
                            int util001(int x) { return x * 1 + 1; }
                            int util002(int x) { return x * 2 + 2; }
                            int util003(int x) { return x * 3 + 3; }
                            int util004(int x) { return x * 4 + 4; }
                            int util005(int x) { return x * 5 + 5; }
                            int util006(int x) { return x * 6 + 6; }
                            int util007(int x) { return x * 7 + 7; }
                            int util008(int x) { return x * 8 + 8; }
                            int util009(int x) { return x * 9 + 9; }
                            int util010(int x) { return x * 10 + 10; }
                            int util011(int x) { return x * 11 + 11; }
                            int util012(int x) { return x * 12 + 12; }
                            int util013(int x) { return x * 13 + 13; }
                            int util014(int x) { return x * 14 + 14; }
                            int util015(int x) { return x * 15 + 15; }
                            int util016(int x) { return x * 16 + 16; }
                            int util017(int x) { return x * 17 + 17; }
                            int util018(int x) { return x * 18 + 18; }
                            int util019(int x) { return x * 19 + 19; }
                            int util020(int x) { return x * 20 + 20; }
                            int util021(int x) { return x * 21 + 21; }
                            int util022(int x) { return x * 22 + 22; }
                            int util023(int x) { return x * 23 + 23; }
                            int util024(int x) { return x * 24 + 24; }
                            int util025(int x) { return x * 25 + 25; }
                            int util026(int x) { return x * 26 + 26; }
                            int util027(int x) { return x * 27 + 27; }
                            int util028(int x) { return x * 28 + 28; }
                            int util029(int x) { return x * 29 + 29; }
                            int util030(int x) { return x * 30 + 30; }
                            int util031(int x) { return x * 31 + 31; }
                            int util032(int x) { return x * 32 + 32; }
                            int util033(int x) { return x * 33 + 33; }
                            int util034(int x) { return x * 34 + 34; }
                            int util035(int x) { return x * 35 + 35; }
                            int util036(int x) { return x * 36 + 36; }
                            int util037(int x) { return x * 37 + 37; }
                            int util038(int x) { return x * 38 + 38; }
                            int util039(int x) { return x * 39 + 39; }
                            int util040(int x) { return x * 40 + 40; }
                            int util041(int x) { return x * 41 + 41; }
                            int util042(int x) { return x * 42 + 42; }
                            int util043(int x) { return x * 43 + 43; }
                            int util044(int x) { return x * 44 + 44; }
                            int util045(int x) { return x * 45 + 45; }
                            int util046(int x) { return x * 46 + 46; }
                            int util047(int x) { return x * 47 + 47; }
                            int util048(int x) { return x * 48 + 48; }
                            int util049(int x) { return x * 49 + 49; }
                            int util050(int x) { return x * 50 + 50; }
                            int util051(int x) { return x * 51 + 51; }
                            int util052(int x) { return x * 52 + 52; }
                            int util053(int x) { return x * 53 + 53; }
                            int util054(int x) { return x * 54 + 54; }
                            int util055(int x) { return x * 55 + 55; }
                            int util056(int x) { return x * 56 + 56; }
                            int util057(int x) { return x * 57 + 57; }
                            int util058(int x) { return x * 58 + 58; }
                            int util059(int x) { return x * 59 + 59; }
                            int util060(int x) { return x * 60 + 60; }
                            int util061(int x) { return x * 61 + 61; }
                            int util062(int x) { return x * 62 + 62; }
                            int util063(int x) { return x * 63 + 63; }
                            int util064(int x) { return x * 64 + 64; }
                            int util065(int x) { return x * 65 + 65; }
                            int util066(int x) { return x * 66 + 66; }
                            int util067(int x) { return x * 67 + 67; }
                            int util068(int x) { return x * 68 + 68; }
                            int util069(int x) { return x * 69 + 69; }
                            int util070(int x) { return x * 70 + 70; }
                            int util071(int x) { return x * 71 + 71; }
                            int util072(int x) { return x * 72 + 72; }
                            int util073(int x) { return x * 73 + 73; }
                            int util074(int x) { return x * 74 + 74; }
                            int util075(int x) { return x * 75 + 75; }
                            int util076(int x) { return x * 76 + 76; }
                            int util077(int x) { return x * 77 + 77; }
                            int util078(int x) { return x * 78 + 78; }
                            int util079(int x) { return x * 79 + 79; }
                            int util080(int x) { return x * 80 + 80; }
                            int util081(int x) { return x * 81 + 81; }
                            int util082(int x) { return x * 82 + 82; }
                            int util083(int x) { return x * 83 + 83; }
                            int util084(int x) { return x * 84 + 84; }
                            int util085(int x) { return x * 85 + 85; }
                            int util086(int x) { return x * 86 + 86; }
                            int util087(int x) { return x * 87 + 87; }
                            int util088(int x) { return x * 88 + 88; }
                            int util089(int x) { return x * 89 + 89; }
                            int util090(int x) { return x * 90 + 90; }
                            int util091(int x) { return x * 91 + 91; }
                            int util092(int x) { return x * 92 + 92; }
                            int util093(int x) { return x * 93 + 93; }
                            int util094(int x) { return x * 94 + 94; }
                            int util095(int x) { return x * 95 + 95; }
                            int util096(int x) { return x * 96 + 96; }
                            int util097(int x) { return x * 97 + 97; }
                            int util098(int x) { return x * 98 + 98; }
                            int util099(int x) { return x * 99 + 99; }
                            int util100(int x) { return x * 100 + 100; }
                        
                            // more padding with loops and conditionals
                            void processBatch1(std::vector<int>& data) {
                                for (size_t i = 0; i < data.size(); ++i) {
                                    if (data[i] < 0) data[i] = 0;
                                    else if (data[i] > 1000) data[i] = 1000;
                                    data[i] = data[i] * 2 + 1;
                                }
                            }
                        
                            void processBatch2(std::vector<int>& data) {
                                for (size_t i = 0; i < data.size(); ++i) {
                                    if (isEven(data[i])) data[i] += 10;
                                    else data[i] -= 5;
                                }
                            }
                        
                            void processBatch3(std::vector<float>& data) {
                                for (size_t i = 0; i < data.size(); ++i) {
                                    data[i] = clampFloat(data[i], 0.0f, 1.0f);
                                    data[i] = data[i] * data[i];
                                }
                            }
                        
                            void fillSequence(std::vector<int>& out, int count) {
                                out.clear();
                                out.reserve(count);
                                for (int i = 0; i < count; ++i) {
                                    out.push_back(i * 3 + 7);
                                }
                            }
                        
                            int sumRange(const std::vector<int>& v, int start, int end) {
                                int s = 0;
                                for (int i = start; i < end && i < static_cast<int>(v.size()); ++i) {
                                    s += v[i];
                                }
                                return s;
                            }
                        
                            float average(const std::vector<float>& v) {
                                if (v.empty()) return 0.0f;
                                float s = 0.0f;
                                for (float x : v) s += x;
                                return s / static_cast<float>(v.size());
                            }
                        
                            // large block of repetitive switch / if logic
                            int classify(int value) {
                                switch (value % 10) {
                                    case 0: return 100;
                                    case 1: return 101;
                                    case 2: return 102;
                                    case 3: return 103;
                                    case 4: return 104;
                                    case 5: return 105;
                                    case 6: return 106;
                                    case 7: return 107;
                                    case 8: return 108;
                                    case 9: return 109;
                                    default: return -1;
                                }
                            }
                        
                            int classify2(int value) {
                                if (value < 0) return -1;
                                if (value < 10) return 0;
                                if (value < 20) return 1;
                                if (value < 30) return 2;
                                if (value < 40) return 3;
                                if (value < 50) return 4;
                                if (value < 60) return 5;
                                if (value < 70) return 6;
                                if (value < 80) return 7;
                                if (value < 90) return 8;
                                return 9;
                            }

                            #include <iostream>
                            
                            int add(int a, int b) {
                                return a + b;
                            }
                            
                            int main() {
                                int x = 5;
                                int y = 10;
                                int result = add(x, y);
                            
                                for (int i = 0; i < 3; i++) {
                                    result += i;
                                }
                            
                                std::cout << result << '\n';
                                return result;
                            }
                                //@prag LuauProton = { squB = eLineCheck } || can be "dLineCheck"
                                #include <iostream>
                                #include <vector>
                                #include <string>
                                #include <map>
                                #include <memory>
                                #include <algorithm>
                                #include <cmath>
                                #include <cassert>
                            
                                namespace TestNamespace {
                            
                                class BaseEntity {
                                public:
                                    BaseEntity() : id_(0), active_(true) {}
                                    virtual ~BaseEntity() {}
                            
                                    virtual void update(float dt) = 0;
                                    virtual void render() const = 0;
                            
                                    int getId() const { return id_; }
                                    void setId(int id) { id_ = id; }
                            
                                    bool isActive() const { return active_; }
                                    void setActive(bool active) { active_ = active; }
                            
                                protected:
                                    int id_;
                                    bool active_;
                                };
                            
                                class Player : public BaseEntity {
                                public:
                                    Player() : health_(100.0f), speed_(5.0f), score_(0) {}
                                    explicit Player(int id) : Player() { setId(id); }
                            
                                    void update(float dt) override {
                                        if (!isActive()) return;
                                        position_x_ += velocity_x_ * dt * speed_;
                                        position_y_ += velocity_y_ * dt * speed_;
                                        if (health_ <= 0.0f) {
                                            setActive(false);
                                        }
                                    }
                            
                                    void render() const override {
                                        if (!isActive()) return;
                                        // placeholder render
                                    }
                            
                                    void takeDamage(float amount) {
                                        health_ -= amount;
                                        if (health_ < 0.0f) health_ = 0.0f;
                                    }
                            
                                    void heal(float amount) {
                                        health_ += amount;
                                        if (health_ > 100.0f) health_ = 100.0f;
                                    }
                            
                                    void addScore(int points) { score_ += points; }
                                    int getScore() const { return score_; }
                                    float getHealth() const { return health_; }
                            
                                    void setVelocity(float vx, float vy) {
                                        velocity_x_ = vx;
                                        velocity_y_ = vy;
                                    }
                            
                                private:
                                    float health_;
                                    float speed_;
                                    int score_;
                                    float position_x_ = 0.0f;
                                    float position_y_ = 0.0f;
                                    float velocity_x_ = 0.0f;
                                    float velocity_y_ = 0.0f;
                                };
                            
                                class Enemy : public BaseEntity {
                                public:
                                    enum class Type { Grunt, Elite, Boss };
                            
                                    Enemy() : type_(Type::Grunt), damage_(10.0f), health_(50.0f) {}
                                    Enemy(Type t, float dmg, float hp) : type_(t), damage_(dmg), health_(hp) {}
                            
                                    void update(float dt) override {
                                        if (!isActive()) return;
                                        // simple AI placeholder
                                        patrolTimer_ += dt;
                                        if (patrolTimer_ > 2.0f) {
                                            direction_ *= -1.0f;
                                            patrolTimer_ = 0.0f;
                                        }
                                        position_x_ += direction_ * 2.0f * dt;
                                    }
                            
                                    void render() const override {
                                        if (!isActive()) return;
                                    }
                            
                                    float getDamage() const { return damage_; }
                                    Type getType() const { return type_; }
                            
                                    void takeDamage(float amount) {
                                        health_ -= amount;
                                        if (health_ <= 0.0f) {
                                            setActive(false);
                                        }
                                    }
                            
                                private:
                                    Type type_;
                                    float damage_;
                                    float health_;
                                    float position_x_ = 0.0f;
                                    float direction_ = 1.0f;
                                    float patrolTimer_ = 0.0f;
                                };
                            
                                class Projectile {
                                public:
                                    Projectile() : alive_(false) {}
                                    Projectile(float x, float y, float vx, float vy, float dmg)
                                        : pos_x_(x), pos_y_(y), vel_x_(vx), vel_y_(vy), damage_(dmg), alive_(true) {}
                            
                                    void update(float dt) {
                                        if (!alive_) return;
                                        pos_x_ += vel_x_ * dt;
                                        pos_y_ += vel_y_ * dt;
                                        lifetime_ += dt;
                                        if (lifetime_ > 3.0f) alive_ = false;
                                    }
                            
                                    bool isAlive() const { return alive_; }
                                    float getDamage() const { return damage_; }
                                    float getX() const { return pos_x_; }
                                    float getY() const { return pos_y_; }
                            
                                    void kill() { alive_ = false; }
                            
                                private:
                                    float pos_x_ = 0.0f;
                                    float pos_y_ = 0.0f;
                                    float vel_x_ = 0.0f;
                                    float vel_y_ = 0.0f;
                                    float damage_ = 0.0f;
                                    float lifetime_ = 0.0f;
                                    bool alive_ = false;
                                };
                            
                                class GameWorld {
                                public:
                                    GameWorld() {
                                        player_ = std::make_unique<Player>(1);
                                        spawnEnemies(20);
                                    }
                            
                                    void spawnEnemies(int count) {
                                        for (int i = 0; i < count; ++i) {
                                            Enemy::Type t = (i % 5 == 0) ? Enemy::Type::Elite : Enemy::Type::Grunt;
                                            float dmg = (t == Enemy::Type::Elite) ? 25.0f : 10.0f;
                                            float hp  = (t == Enemy::Type::Elite) ? 120.0f : 50.0f;
                                            enemies_.emplace_back(t, dmg, hp);
                                            enemies_.back().setId(100 + i);
                                        }
                                    }
                            
                                    void update(float dt) {
                                        if (player_) player_->update(dt);
                            
                                        for (auto& e : enemies_) {
                                            if (e.isActive()) e.update(dt);
                                        }
                            
                                        for (auto& p : projectiles_) {
                                            p.update(dt);
                                        }
                            
                                        // simple collision placeholder
                                        for (auto& p : projectiles_) {
                                            if (!p.isAlive()) continue;
                                            for (auto& e : enemies_) {
                                                if (!e.isActive()) continue;
                                                // pretend hit
                                                if (std::abs(p.getX() - 0.0f) < 1.0f) {
                                                    e.takeDamage(p.getDamage());
                                                    p.kill();
                                                    if (player_) player_->addScore(10);
                                                }
                                            }
                                        }
                            
                                        // cleanup dead projectiles
                                        projectiles_.erase(
                                            std::remove_if(projectiles_.begin(), projectiles_.end(),
                                                [](const Projectile& p) { return !p.isAlive(); }),
                                            projectiles_.end());
                                    }
                            
                                    void render() const {
                                        if (player_) player_->render();
                                        for (const auto& e : enemies_) {
                                            if (e.isActive()) e.render();
                                        }
                                    }
                            
                                    void fireProjectile(float x, float y, float vx, float vy, float dmg) {
                                        projectiles_.emplace_back(x, y, vx, vy, dmg);
                                    }
                            
                                    Player* getPlayer() { return player_.get(); }
                                    const std::vector<Enemy>& getEnemies() const { return enemies_; }
                            
                                private:
                                    std::unique_ptr<Player> player_;
                                    std::vector<Enemy> enemies_;
                                    std::vector<Projectile> projectiles_;
                                };
                            
                                // ---------- repetitive helper functions to pad line count ----------
                            
                                int add(int a, int b) { return a + b; }
                                int sub(int a, int b) { return a - b; }
                                int mul(int a, int b) { return a * b; }
                                int div_safe(int a, int b) { return b != 0 ? a / b : 0; }
                            
                                float addf(float a, float b) { return a + b; }
                                float subf(float a, float b) { return a - b; }
                                float mulf(float a, float b) { return a * b; }
                                float divf(float a, float b) { return b != 0.0f ? a / b : 0.0f; }
                            
                                bool isEven(int n) { return n % 2 == 0; }
                                bool isOdd(int n) { return n % 2 != 0; }
                                bool isPositive(int n) { return n > 0; }
                                bool isNegative(int n) { return n < 0; }
                            
                                int clampInt(int v, int lo, int hi) {
                                    if (v < lo) return lo;
                                    if (v > hi) return hi;
                                    return v;
                                }
                            
                                float clampFloat(float v, float lo, float hi) {
                                    if (v < lo) return lo;
                                    if (v > hi) return hi;
                                    return v;
                                }
                            
                                int maxInt(int a, int b) { return a > b ? a : b; }
                                int minInt(int a, int b) { return a < b ? a : b; }
                                float maxFloat(float a, float b) { return a > b ? a : b; }
                                float minFloat(float a, float b) { return a < b ? a : b; }
                            
                                // generate a lot of nearly identical utility functions
                                int util001(int x) { return x * 1 + 1; }
                                int util002(int x) { return x * 2 + 2; }
                                int util003(int x) { return x * 3 + 3; }
                                int util004(int x) { return x * 4 + 4; }
                                int util005(int x) { return x * 5 + 5; }
                                int util006(int x) { return x * 6 + 6; }
                                int util007(int x) { return x * 7 + 7; }
                                int util008(int x) { return x * 8 + 8; }
                                int util009(int x) { return x * 9 + 9; }
                                int util010(int x) { return x * 10 + 10; }
                                int util011(int x) { return x * 11 + 11; }
                                int util012(int x) { return x * 12 + 12; }
                                int util013(int x) { return x * 13 + 13; }
                                int util014(int x) { return x * 14 + 14; }
                                int util015(int x) { return x * 15 + 15; }
                                int util016(int x) { return x * 16 + 16; }
                                int util017(int x) { return x * 17 + 17; }
                                int util018(int x) { return x * 18 + 18; }
                                int util019(int x) { return x * 19 + 19; }
                                int util020(int x) { return x * 20 + 20; }
                                int util021(int x) { return x * 21 + 21; }
                                int util022(int x) { return x * 22 + 22; }
                                int util023(int x) { return x * 23 + 23; }
                                int util024(int x) { return x * 24 + 24; }
                                int util025(int x) { return x * 25 + 25; }
                                int util026(int x) { return x * 26 + 26; }
                                int util027(int x) { return x * 27 + 27; }
                                int util028(int x) { return x * 28 + 28; }
                                int util029(int x) { return x * 29 + 29; }
                                int util030(int x) { return x * 30 + 30; }
                                int util031(int x) { return x * 31 + 31; }
                                int util032(int x) { return x * 32 + 32; }
                                int util033(int x) { return x * 33 + 33; }
                                int util034(int x) { return x * 34 + 34; }
                                int util035(int x) { return x * 35 + 35; }
                                int util036(int x) { return x * 36 + 36; }
                                int util037(int x) { return x * 37 + 37; }
                                int util038(int x) { return x * 38 + 38; }
                                int util039(int x) { return x * 39 + 39; }
                                int util040(int x) { return x * 40 + 40; }
                                int util041(int x) { return x * 41 + 41; }
                                int util042(int x) { return x * 42 + 42; }
                                int util043(int x) { return x * 43 + 43; }
                                int util044(int x) { return x * 44 + 44; }
                                int util045(int x) { return x * 45 + 45; }
                                int util046(int x) { return x * 46 + 46; }
                                int util047(int x) { return x * 47 + 47; }
                                int util048(int x) { return x * 48 + 48; }
                                int util049(int x) { return x * 49 + 49; }
                                int util050(int x) { return x * 50 + 50; }
                                int util051(int x) { return x * 51 + 51; }
                                int util052(int x) { return x * 52 + 52; }
                                int util053(int x) { return x * 53 + 53; }
                                int util054(int x) { return x * 54 + 54; }
                                int util055(int x) { return x * 55 + 55; }
                                int util056(int x) { return x * 56 + 56; }
                                int util057(int x) { return x * 57 + 57; }
                                int util058(int x) { return x * 58 + 58; }
                                int util059(int x) { return x * 59 + 59; }
                                int util060(int x) { return x * 60 + 60; }
                                int util061(int x) { return x * 61 + 61; }
                                int util062(int x) { return x * 62 + 62; }
                                int util063(int x) { return x * 63 + 63; }
                                int util064(int x) { return x * 64 + 64; }
                                int util065(int x) { return x * 65 + 65; }
                                int util066(int x) { return x * 66 + 66; }
                                int util067(int x) { return x * 67 + 67; }
                                int util068(int x) { return x * 68 + 68; }
                                int util069(int x) { return x * 69 + 69; }
                                int util070(int x) { return x * 70 + 70; }
                                int util071(int x) { return x * 71 + 71; }
                                int util072(int x) { return x * 72 + 72; }
                                int util073(int x) { return x * 73 + 73; }
                                int util074(int x) { return x * 74 + 74; }
                                int util075(int x) { return x * 75 + 75; }
                                int util076(int x) { return x * 76 + 76; }
                                int util077(int x) { return x * 77 + 77; }
                                int util078(int x) { return x * 78 + 78; }
                                int util079(int x) { return x * 79 + 79; }
                                int util080(int x) { return x * 80 + 80; }
                                int util081(int x) { return x * 81 + 81; }
                                int util082(int x) { return x * 82 + 82; }
                                int util083(int x) { return x * 83 + 83; }
                                int util084(int x) { return x * 84 + 84; }
                                int util085(int x) { return x * 85 + 85; }
                                int util086(int x) { return x * 86 + 86; }
                                int util087(int x) { return x * 87 + 87; }
                                int util088(int x) { return x * 88 + 88; }
                                int util089(int x) { return x * 89 + 89; }
                                int util090(int x) { return x * 90 + 90; }
                                int util091(int x) { return x * 91 + 91; }
                                int util092(int x) { return x * 92 + 92; }
                                int util093(int x) { return x * 93 + 93; }
                                int util094(int x) { return x * 94 + 94; }
                                int util095(int x) { return x * 95 + 95; }
                                int util096(int x) { return x * 96 + 96; }
                                int util097(int x) { return x * 97 + 97; }
                                int util098(int x) { return x * 98 + 98; }
                                int util099(int x) { return x * 99 + 99; }
                                int util100(int x) { return x * 100 + 100; }
                            
                                // more padding with loops and conditionals
                                void processBatch1(std::vector<int>& data) {
                                    for (size_t i = 0; i < data.size(); ++i) {
                                        if (data[i] < 0) data[i] = 0;
                                        else if (data[i] > 1000) data[i] = 1000;
                                        data[i] = data[i] * 2 + 1;
                                    }
                                }
                            
                                void processBatch2(std::vector<int>& data) {
                                    for (size_t i = 0; i < data.size(); ++i) {
                                        if (isEven(data[i])) data[i] += 10;
                                        else data[i] -= 5;
                                    }
                                }
                            
                                void processBatch3(std::vector<float>& data) {
                                    for (size_t i = 0; i < data.size(); ++i) {
                                        data[i] = clampFloat(data[i], 0.0f, 1.0f);
                                        data[i] = data[i] * data[i];
                                    }
                                }
                            
                                void fillSequence(std::vector<int>& out, int count) {
                                    out.clear();
                                    out.reserve(count);
                                    for (int i = 0; i < count; ++i) {
                                        out.push_back(i * 3 + 7);
                                    }
                                }
                            
                                int sumRange(const std::vector<int>& v, int start, int end) {
                                    int s = 0;
                                    for (int i = start; i < end && i < static_cast<int>(v.size()); ++i) {
                                        s += v[i];
                                    }
                                    return s;
                                }
                            
                                float average(const std::vector<float>& v) {
                                    if (v.empty()) return 0.0f;
                                    float s = 0.0f;
                                    for (float x : v) s += x;
                                    return s / static_cast<float>(v.size());
                                }
                            
                                // large block of repetitive switch / if logic
                                int classify(int value) {
                                    switch (value % 10) {
                                        case 0: return 100;
                                        case 1: return 101;
                                        case 2: return 102;
                                        case 3: return 103;
                                        case 4: return 104;
                                        case 5: return 105;
                                        case 6: return 106;
                                        case 7: return 107;
                                        case 8: return 108;
                                        case 9: return 109;
                                        default: return -1;
                                    }
                                }
                            
                                int classify2(int value) {
                                    if (value < 0) return -1;
                                    if (value < 10) return 0;
                                    if (value < 20) return 1;
                                    if (value < 30) return 2;
                                    if (value < 40) return 3;
                                    if (value < 50) return 4;
                                    if (value < 60) return 5;
                                    if (value < 70) return 6;
                                    if (value < 80) return 7;
                                    if (value < 90) return 8;
                                    return 9;
                                }
                                #include <iostream>
                                
                                int add(int a, int b) {
                                    return a + b;
                                }
                                
                                int main() {
                                    int x = 5;
                                    int y = 10;
                                    int result = add(x, y);
                                
                                    for (int i = 0; i < 3; i++) {
                                        result += i;
                                    }
                                
                                    std::cout << result << '\n';
                                    return result;
                                }
                                    //@prag LuauProton = { squB = eLineCheck } || can be "dLineCheck"
                                    #include <iostream>
                                    #include <vector>
                                    #include <string>
                                    #include <map>
                                    #include <memory>
                                    #include <algorithm>
                                    #include <cmath>
                                    #include <cassert>
                                
                                    namespace TestNamespace {
                                
                                    class BaseEntity {
                                    public:
                                        BaseEntity() : id_(0), active_(true) {}
                                        virtual ~BaseEntity() {}
                                
                                        virtual void update(float dt) = 0;
                                        virtual void render() const = 0;
                                
                                        int getId() const { return id_; }
                                        void setId(int id) { id_ = id; }
                                
                                        bool isActive() const { return active_; }
                                        void setActive(bool active) { active_ = active; }
                                
                                    protected:
                                        int id_;
                                        bool active_;
                                    };
                                
                                    class Player : public BaseEntity {
                                    public:
                                        Player() : health_(100.0f), speed_(5.0f), score_(0) {}
                                        explicit Player(int id) : Player() { setId(id); }
                                
                                        void update(float dt) override {
                                            if (!isActive()) return;
                                            position_x_ += velocity_x_ * dt * speed_;
                                            position_y_ += velocity_y_ * dt * speed_;
                                            if (health_ <= 0.0f) {
                                                setActive(false);
                                            }
                                        }
                                
                                        void render() const override {
                                            if (!isActive()) return;
                                            // placeholder render
                                        }
                                
                                        void takeDamage(float amount) {
                                            health_ -= amount;
                                            if (health_ < 0.0f) health_ = 0.0f;
                                        }
                                
                                        void heal(float amount) {
                                            health_ += amount;
                                            if (health_ > 100.0f) health_ = 100.0f;
                                        }
                                
                                        void addScore(int points) { score_ += points; }
                                        int getScore() const { return score_; }
                                        float getHealth() const { return health_; }
                                
                                        void setVelocity(float vx, float vy) {
                                            velocity_x_ = vx;
                                            velocity_y_ = vy;
                                        }
                                
                                    private:
                                        float health_;
                                        float speed_;
                                        int score_;
                                        float position_x_ = 0.0f;
                                        float position_y_ = 0.0f;
                                        float velocity_x_ = 0.0f;
                                        float velocity_y_ = 0.0f;
                                    };
                                
                                    class Enemy : public BaseEntity {
                                    public:
                                        enum class Type { Grunt, Elite, Boss };
                                
                                        Enemy() : type_(Type::Grunt), damage_(10.0f), health_(50.0f) {}
                                        Enemy(Type t, float dmg, float hp) : type_(t), damage_(dmg), health_(hp) {}
                                
                                        void update(float dt) override {
                                            if (!isActive()) return;
                                            // simple AI placeholder
                                            patrolTimer_ += dt;
                                            if (patrolTimer_ > 2.0f) {
                                                direction_ *= -1.0f;
                                                patrolTimer_ = 0.0f;
                                            }
                                            position_x_ += direction_ * 2.0f * dt;
                                        }
                                
                                        void render() const override {
                                            if (!isActive()) return;
                                        }
                                
                                        float getDamage() const { return damage_; }
                                        Type getType() const { return type_; }
                                
                                        void takeDamage(float amount) {
                                            health_ -= amount;
                                            if (health_ <= 0.0f) {
                                                setActive(false);
                                            }
                                        }
                                
                                    private:
                                        Type type_;
                                        float damage_;
                                        float health_;
                                        float position_x_ = 0.0f;
                                        float direction_ = 1.0f;
                                        float patrolTimer_ = 0.0f;
                                    };
                                
                                    class Projectile {
                                    public:
                                        Projectile() : alive_(false) {}
                                        Projectile(float x, float y, float vx, float vy, float dmg)
                                            : pos_x_(x), pos_y_(y), vel_x_(vx), vel_y_(vy), damage_(dmg), alive_(true) {}
                                
                                        void update(float dt) {
                                            if (!alive_) return;
                                            pos_x_ += vel_x_ * dt;
                                            pos_y_ += vel_y_ * dt;
                                            lifetime_ += dt;
                                            if (lifetime_ > 3.0f) alive_ = false;
                                        }
                                
                                        bool isAlive() const { return alive_; }
                                        float getDamage() const { return damage_; }
                                        float getX() const { return pos_x_; }
                                        float getY() const { return pos_y_; }
                                
                                        void kill() { alive_ = false; }
                                
                                    private:
                                        float pos_x_ = 0.0f;
                                        float pos_y_ = 0.0f;
                                        float vel_x_ = 0.0f;
                                        float vel_y_ = 0.0f;
                                        float damage_ = 0.0f;
                                        float lifetime_ = 0.0f;
                                        bool alive_ = false;
                                    };
                                
                                    class GameWorld {
                                    public:
                                        GameWorld() {
                                            player_ = std::make_unique<Player>(1);
                                            spawnEnemies(20);
                                        }
                                
                                        void spawnEnemies(int count) {
                                            for (int i = 0; i < count; ++i) {
                                                Enemy::Type t = (i % 5 == 0) ? Enemy::Type::Elite : Enemy::Type::Grunt;
                                                float dmg = (t == Enemy::Type::Elite) ? 25.0f : 10.0f;
                                                float hp  = (t == Enemy::Type::Elite) ? 120.0f : 50.0f;
                                                enemies_.emplace_back(t, dmg, hp);
                                                enemies_.back().setId(100 + i);
                                            }
                                        }
                                
                                        void update(float dt) {
                                            if (player_) player_->update(dt);
                                
                                            for (auto& e : enemies_) {
                                                if (e.isActive()) e.update(dt);
                                            }
                                
                                            for (auto& p : projectiles_) {
                                                p.update(dt);
                                            }
                                
                                            // simple collision placeholder
                                            for (auto& p : projectiles_) {
                                                if (!p.isAlive()) continue;
                                                for (auto& e : enemies_) {
                                                    if (!e.isActive()) continue;
                                                    // pretend hit
                                                    if (std::abs(p.getX() - 0.0f) < 1.0f) {
                                                        e.takeDamage(p.getDamage());
                                                        p.kill();
                                                        if (player_) player_->addScore(10);
                                                    }
                                                }
                                            }
                                
                                            // cleanup dead projectiles
                                            projectiles_.erase(
                                                std::remove_if(projectiles_.begin(), projectiles_.end(),
                                                    [](const Projectile& p) { return !p.isAlive(); }),
                                                projectiles_.end());
                                        }
                                
                                        void render() const {
                                            if (player_) player_->render();
                                            for (const auto& e : enemies_) {
                                                if (e.isActive()) e.render();
                                            }
                                        }
                                
                                        void fireProjectile(float x, float y, float vx, float vy, float dmg) {
                                            projectiles_.emplace_back(x, y, vx, vy, dmg);
                                        }
                                
                                        Player* getPlayer() { return player_.get(); }
                                        const std::vector<Enemy>& getEnemies() const { return enemies_; }
                                
                                    private:
                                        std::unique_ptr<Player> player_;
                                        std::vector<Enemy> enemies_;
                                        std::vector<Projectile> projectiles_;
                                    };
                                
                                    // ---------- repetitive helper functions to pad line count ----------
                                
                                    int add(int a, int b) { return a + b; }
                                    int sub(int a, int b) { return a - b; }
                                    int mul(int a, int b) { return a * b; }
                                    int div_safe(int a, int b) { return b != 0 ? a / b : 0; }
                                
                                    float addf(float a, float b) { return a + b; }
                                    float subf(float a, float b) { return a - b; }
                                    float mulf(float a, float b) { return a * b; }
                                    float divf(float a, float b) { return b != 0.0f ? a / b : 0.0f; }
                                
                                    bool isEven(int n) { return n % 2 == 0; }
                                    bool isOdd(int n) { return n % 2 != 0; }
                                    bool isPositive(int n) { return n > 0; }
                                    bool isNegative(int n) { return n < 0; }
                                
                                    int clampInt(int v, int lo, int hi) {
                                        if (v < lo) return lo;
                                        if (v > hi) return hi;
                                        return v;
                                    }
                                
                                    float clampFloat(float v, float lo, float hi) {
                                        if (v < lo) return lo;
                                        if (v > hi) return hi;
                                        return v;
                                    }
                                
                                    int maxInt(int a, int b) { return a > b ? a : b; }
                                    int minInt(int a, int b) { return a < b ? a : b; }
                                    float maxFloat(float a, float b) { return a > b ? a : b; }
                                    float minFloat(float a, float b) { return a < b ? a : b; }
                                
                                    // generate a lot of nearly identical utility functions
                                    int util001(int x) { return x * 1 + 1; }
                                    int util002(int x) { return x * 2 + 2; }
                                    int util003(int x) { return x * 3 + 3; }
                                    int util004(int x) { return x * 4 + 4; }
                                    int util005(int x) { return x * 5 + 5; }
                                    int util006(int x) { return x * 6 + 6; }
                                    int util007(int x) { return x * 7 + 7; }
                                    int util008(int x) { return x * 8 + 8; }
                                    int util009(int x) { return x * 9 + 9; }
                                    int util010(int x) { return x * 10 + 10; }
                                    int util011(int x) { return x * 11 + 11; }
                                    int util012(int x) { return x * 12 + 12; }
                                    int util013(int x) { return x * 13 + 13; }
                                    int util014(int x) { return x * 14 + 14; }
                                    int util015(int x) { return x * 15 + 15; }
                                    int util016(int x) { return x * 16 + 16; }
                                    int util017(int x) { return x * 17 + 17; }
                                    int util018(int x) { return x * 18 + 18; }
                                    int util019(int x) { return x * 19 + 19; }
                                    int util020(int x) { return x * 20 + 20; }
                                    int util021(int x) { return x * 21 + 21; }
                                    int util022(int x) { return x * 22 + 22; }
                                    int util023(int x) { return x * 23 + 23; }
                                    int util024(int x) { return x * 24 + 24; }
                                    int util025(int x) { return x * 25 + 25; }
                                    int util026(int x) { return x * 26 + 26; }
                                    int util027(int x) { return x * 27 + 27; }
                                    int util028(int x) { return x * 28 + 28; }
                                    int util029(int x) { return x * 29 + 29; }
                                    int util030(int x) { return x * 30 + 30; }
                                    int util031(int x) { return x * 31 + 31; }
                                    int util032(int x) { return x * 32 + 32; }
                                    int util033(int x) { return x * 33 + 33; }
                                    int util034(int x) { return x * 34 + 34; }
                                    int util035(int x) { return x * 35 + 35; }
                                    int util036(int x) { return x * 36 + 36; }
                                    int util037(int x) { return x * 37 + 37; }
                                    int util038(int x) { return x * 38 + 38; }
                                    int util039(int x) { return x * 39 + 39; }
                                    int util040(int x) { return x * 40 + 40; }
                                    int util041(int x) { return x * 41 + 41; }
                                    int util042(int x) { return x * 42 + 42; }
                                    int util043(int x) { return x * 43 + 43; }
                                    int util044(int x) { return x * 44 + 44; }
                                    int util045(int x) { return x * 45 + 45; }
                                    int util046(int x) { return x * 46 + 46; }
                                    int util047(int x) { return x * 47 + 47; }
                                    int util048(int x) { return x * 48 + 48; }
                                    int util049(int x) { return x * 49 + 49; }
                                    int util050(int x) { return x * 50 + 50; }
                                    int util051(int x) { return x * 51 + 51; }
                                    int util052(int x) { return x * 52 + 52; }
                                    int util053(int x) { return x * 53 + 53; }
                                    int util054(int x) { return x * 54 + 54; }
                                    int util055(int x) { return x * 55 + 55; }
                                    int util056(int x) { return x * 56 + 56; }
                                    int util057(int x) { return x * 57 + 57; }
                                    int util058(int x) { return x * 58 + 58; }
                                    int util059(int x) { return x * 59 + 59; }
                                    int util060(int x) { return x * 60 + 60; }
                                    int util061(int x) { return x * 61 + 61; }
                                    int util062(int x) { return x * 62 + 62; }
                                    int util063(int x) { return x * 63 + 63; }
                                    int util064(int x) { return x * 64 + 64; }
                                    int util065(int x) { return x * 65 + 65; }
                                    int util066(int x) { return x * 66 + 66; }
                                    int util067(int x) { return x * 67 + 67; }
                                    int util068(int x) { return x * 68 + 68; }
                                    int util069(int x) { return x * 69 + 69; }
                                    int util070(int x) { return x * 70 + 70; }
                                    int util071(int x) { return x * 71 + 71; }
                                    int util072(int x) { return x * 72 + 72; }
                                    int util073(int x) { return x * 73 + 73; }
                                    int util074(int x) { return x * 74 + 74; }
                                    int util075(int x) { return x * 75 + 75; }
                                    int util076(int x) { return x * 76 + 76; }
                                    int util077(int x) { return x * 77 + 77; }
                                    int util078(int x) { return x * 78 + 78; }
                                    int util079(int x) { return x * 79 + 79; }
                                    int util080(int x) { return x * 80 + 80; }
                                    int util081(int x) { return x * 81 + 81; }
                                    int util082(int x) { return x * 82 + 82; }
                                    int util083(int x) { return x * 83 + 83; }
                                    int util084(int x) { return x * 84 + 84; }
                                    int util085(int x) { return x * 85 + 85; }
                                    int util086(int x) { return x * 86 + 86; }
                                    int util087(int x) { return x * 87 + 87; }
                                    int util088(int x) { return x * 88 + 88; }
                                    int util089(int x) { return x * 89 + 89; }
                                    int util090(int x) { return x * 90 + 90; }
                                    int util091(int x) { return x * 91 + 91; }
                                    int util092(int x) { return x * 92 + 92; }
                                    int util093(int x) { return x * 93 + 93; }
                                    int util094(int x) { return x * 94 + 94; }
                                    int util095(int x) { return x * 95 + 95; }
                                    int util096(int x) { return x * 96 + 96; }
                                    int util097(int x) { return x * 97 + 97; }
                                    int util098(int x) { return x * 98 + 98; }
                                    int util099(int x) { return x * 99 + 99; }
                                    int util100(int x) { return x * 100 + 100; }
                                
                                    // more padding with loops and conditionals
                                    void processBatch1(std::vector<int>& data) {
                                        for (size_t i = 0; i < data.size(); ++i) {
                                            if (data[i] < 0) data[i] = 0;
                                            else if (data[i] > 1000) data[i] = 1000;
                                            data[i] = data[i] * 2 + 1;
                                        }
                                    }
                                
                                    void processBatch2(std::vector<int>& data) {
                                        for (size_t i = 0; i < data.size(); ++i) {
                                            if (isEven(data[i])) data[i] += 10;
                                            else data[i] -= 5;
                                        }
                                    }
                                
                                    void processBatch3(std::vector<float>& data) {
                                        for (size_t i = 0; i < data.size(); ++i) {
                                            data[i] = clampFloat(data[i], 0.0f, 1.0f);
                                            data[i] = data[i] * data[i];
                                        }
                                    }
                                
                                    void fillSequence(std::vector<int>& out, int count) {
                                        out.clear();
                                        out.reserve(count);
                                        for (int i = 0; i < count; ++i) {
                                            out.push_back(i * 3 + 7);
                                        }
                                    }
                                
                                    int sumRange(const std::vector<int>& v, int start, int end) {
                                        int s = 0;
                                        for (int i = start; i < end && i < static_cast<int>(v.size()); ++i) {
                                            s += v[i];
                                        }
                                        return s;
                                    }
                                
                                    float average(const std::vector<float>& v) {
                                        if (v.empty()) return 0.0f;
                                        float s = 0.0f;
                                        for (float x : v) s += x;
                                        return s / static_cast<float>(v.size());
                                    }
                                
                                    // large block of repetitive switch / if logic
                                    int classify(int value) {
                                        switch (value % 10) {
                                            case 0: return 100;
                                            case 1: return 101;
                                            case 2: return 102;
                                            case 3: return 103;
                                            case 4: return 104;
                                            case 5: return 105;
                                            case 6: return 106;
                                            case 7: return 107;
                                            case 8: return 108;
                                            case 9: return 109;
                                            default: return -1;
                                        }
                                    }
                                
                                    int classify2(int value) {
                                        if (value < 0) return -1;
                                        if (value < 10) return 0;
                                        if (value < 20) return 1;
                                        if (value < 30) return 2;
                                        if (value < 40) return 3;
                                        if (value < 50) return 4;
                                        if (value < 60) return 5;
                                        if (value < 70) return 6;
                                        if (value < 80) return 7;
                                        if (value < 90) return 8;
                                        return 9;
                                    }
                                    #include <iostream>
                                    
                                    int add(int a, int b) {
                                        return a + b;
                                    }
                                    
                                    int main() {
                                        int x = 5;
                                        int y = 10;
                                        int result = add(x, y);
                                    
                                        for (int i = 0; i < 3; i++) {
                                            result += i;
                                        }
                                    
                                        std::cout << result << '\n';
                                        return result;
                                    }
                                        //@prag LuauProton = { squB = eLineCheck } || can be "dLineCheck"
                                        #include <iostream>
                                        #include <vector>
                                        #include <string>
                                        #include <map>
                                        #include <memory>
                                        #include <algorithm>
                                        #include <cmath>
                                        #include <cassert>
                                    
                                        namespace TestNamespace {
                                    
                                        class BaseEntity {
                                        public:
                                            BaseEntity() : id_(0), active_(true) {}
                                            virtual ~BaseEntity() {}
                                    
                                            virtual void update(float dt) = 0;
                                            virtual void render() const = 0;
                                    
                                            int getId() const { return id_; }
                                            void setId(int id) { id_ = id; }
                                    
                                            bool isActive() const { return active_; }
                                            void setActive(bool active) { active_ = active; }
                                    
                                        protected:
                                            int id_;
                                            bool active_;
                                        };
                                    
                                        class Player : public BaseEntity {
                                        public:
                                            Player() : health_(100.0f), speed_(5.0f), score_(0) {}
                                            explicit Player(int id) : Player() { setId(id); }
                                    
                                            void update(float dt) override {
                                                if (!isActive()) return;
                                                position_x_ += velocity_x_ * dt * speed_;
                                                position_y_ += velocity_y_ * dt * speed_;
                                                if (health_ <= 0.0f) {
                                                    setActive(false);
                                                }
                                            }
                                    
                                            void render() const override {
                                                if (!isActive()) return;
                                                // placeholder render
                                            }
                                    
                                            void takeDamage(float amount) {
                                                health_ -= amount;
                                                if (health_ < 0.0f) health_ = 0.0f;
                                            }
                                    
                                            void heal(float amount) {
                                                health_ += amount;
                                                if (health_ > 100.0f) health_ = 100.0f;
                                            }
                                    
                                            void addScore(int points) { score_ += points; }
                                            int getScore() const { return score_; }
                                            float getHealth() const { return health_; }
                                    
                                            void setVelocity(float vx, float vy) {
                                                velocity_x_ = vx;
                                                velocity_y_ = vy;
                                            }
                                    
                                        private:
                                            float health_;
                                            float speed_;
                                            int score_;
                                            float position_x_ = 0.0f;
                                            float position_y_ = 0.0f;
                                            float velocity_x_ = 0.0f;
                                            float velocity_y_ = 0.0f;
                                        };
                                    
                                        class Enemy : public BaseEntity {
                                        public:
                                            enum class Type { Grunt, Elite, Boss };
                                    
                                            Enemy() : type_(Type::Grunt), damage_(10.0f), health_(50.0f) {}
                                            Enemy(Type t, float dmg, float hp) : type_(t), damage_(dmg), health_(hp) {}
                                    
                                            void update(float dt) override {
                                                if (!isActive()) return;
                                                // simple AI placeholder
                                                patrolTimer_ += dt;
                                                if (patrolTimer_ > 2.0f) {
                                                    direction_ *= -1.0f;
                                                    patrolTimer_ = 0.0f;
                                                }
                                                position_x_ += direction_ * 2.0f * dt;
                                            }
                                    
                                            void render() const override {
                                                if (!isActive()) return;
                                            }
                                    
                                            float getDamage() const { return damage_; }
                                            Type getType() const { return type_; }
                                    
                                            void takeDamage(float amount) {
                                                health_ -= amount;
                                                if (health_ <= 0.0f) {
                                                    setActive(false);
                                                }
                                            }
                                    
                                        private:
                                            Type type_;
                                            float damage_;
                                            float health_;
                                            float position_x_ = 0.0f;
                                            float direction_ = 1.0f;
                                            float patrolTimer_ = 0.0f;
                                        };
                                    
                                        class Projectile {
                                        public:
                                            Projectile() : alive_(false) {}
                                            Projectile(float x, float y, float vx, float vy, float dmg)
                                                : pos_x_(x), pos_y_(y), vel_x_(vx), vel_y_(vy), damage_(dmg), alive_(true) {}
                                    
                                            void update(float dt) {
                                                if (!alive_) return;
                                                pos_x_ += vel_x_ * dt;
                                                pos_y_ += vel_y_ * dt;
                                                lifetime_ += dt;
                                                if (lifetime_ > 3.0f) alive_ = false;
                                            }
                                    
                                            bool isAlive() const { return alive_; }
                                            float getDamage() const { return damage_; }
                                            float getX() const { return pos_x_; }
                                            float getY() const { return pos_y_; }
                                    
                                            void kill() { alive_ = false; }
                                    
                                        private:
                                            float pos_x_ = 0.0f;
                                            float pos_y_ = 0.0f;
                                            float vel_x_ = 0.0f;
                                            float vel_y_ = 0.0f;
                                            float damage_ = 0.0f;
                                            float lifetime_ = 0.0f;
                                            bool alive_ = false;
                                        };
                                    
                                        class GameWorld {
                                        public:
                                            GameWorld() {
                                                player_ = std::make_unique<Player>(1);
                                                spawnEnemies(20);
                                            }
                                    
                                            void spawnEnemies(int count) {
                                                for (int i = 0; i < count; ++i) {
                                                    Enemy::Type t = (i % 5 == 0) ? Enemy::Type::Elite : Enemy::Type::Grunt;
                                                    float dmg = (t == Enemy::Type::Elite) ? 25.0f : 10.0f;
                                                    float hp  = (t == Enemy::Type::Elite) ? 120.0f : 50.0f;
                                                    enemies_.emplace_back(t, dmg, hp);
                                                    enemies_.back().setId(100 + i);
                                                }
                                            }
                                    
                                            void update(float dt) {
                                                if (player_) player_->update(dt);
                                    
                                                for (auto& e : enemies_) {
                                                    if (e.isActive()) e.update(dt);
                                                }
                                    
                                                for (auto& p : projectiles_) {
                                                    p.update(dt);
                                                }
                                    
                                                // simple collision placeholder
                                                for (auto& p : projectiles_) {
                                                    if (!p.isAlive()) continue;
                                                    for (auto& e : enemies_) {
                                                        if (!e.isActive()) continue;
                                                        // pretend hit
                                                        if (std::abs(p.getX() - 0.0f) < 1.0f) {
                                                            e.takeDamage(p.getDamage());
                                                            p.kill();
                                                            if (player_) player_->addScore(10);
                                                        }
                                                    }
                                                }
                                    
                                                // cleanup dead projectiles
                                                projectiles_.erase(
                                                    std::remove_if(projectiles_.begin(), projectiles_.end(),
                                                        [](const Projectile& p) { return !p.isAlive(); }),
                                                    projectiles_.end());
                                            }
                                    
                                            void render() const {
                                                if (player_) player_->render();
                                                for (const auto& e : enemies_) {
                                                    if (e.isActive()) e.render();
                                                }
                                            }
                                    
                                            void fireProjectile(float x, float y, float vx, float vy, float dmg) {
                                                projectiles_.emplace_back(x, y, vx, vy, dmg);
                                            }
                                    
                                            Player* getPlayer() { return player_.get(); }
                                            const std::vector<Enemy>& getEnemies() const { return enemies_; }
                                    
                                        private:
                                            std::unique_ptr<Player> player_;
                                            std::vector<Enemy> enemies_;
                                            std::vector<Projectile> projectiles_;
                                        };
                                    
                                        // ---------- repetitive helper functions to pad line count ----------
                                    
                                        int add(int a, int b) { return a + b; }
                                        int sub(int a, int b) { return a - b; }
                                        int mul(int a, int b) { return a * b; }
                                        int div_safe(int a, int b) { return b != 0 ? a / b : 0; }
                                    
                                        float addf(float a, float b) { return a + b; }
                                        float subf(float a, float b) { return a - b; }
                                        float mulf(float a, float b) { return a * b; }
                                        float divf(float a, float b) { return b != 0.0f ? a / b : 0.0f; }
                                    
                                        bool isEven(int n) { return n % 2 == 0; }
                                        bool isOdd(int n) { return n % 2 != 0; }
                                        bool isPositive(int n) { return n > 0; }
                                        bool isNegative(int n) { return n < 0; }
                                    
                                        int clampInt(int v, int lo, int hi) {
                                            if (v < lo) return lo;
                                            if (v > hi) return hi;
                                            return v;
                                        }
                                    
                                        float clampFloat(float v, float lo, float hi) {
                                            if (v < lo) return lo;
                                            if (v > hi) return hi;
                                            return v;
                                        }
                                    
                                        int maxInt(int a, int b) { return a > b ? a : b; }
                                        int minInt(int a, int b) { return a < b ? a : b; }
                                        float maxFloat(float a, float b) { return a > b ? a : b; }
                                        float minFloat(float a, float b) { return a < b ? a : b; }
                                    
                                        // generate a lot of nearly identical utility functions
                                        int util001(int x) { return x * 1 + 1; }
                                        int util002(int x) { return x * 2 + 2; }
                                        int util003(int x) { return x * 3 + 3; }
                                        int util004(int x) { return x * 4 + 4; }
                                        int util005(int x) { return x * 5 + 5; }
                                        int util006(int x) { return x * 6 + 6; }
                                        int util007(int x) { return x * 7 + 7; }
                                        int util008(int x) { return x * 8 + 8; }
                                        int util009(int x) { return x * 9 + 9; }
                                        int util010(int x) { return x * 10 + 10; }
                                        int util011(int x) { return x * 11 + 11; }
                                        int util012(int x) { return x * 12 + 12; }
                                        int util013(int x) { return x * 13 + 13; }
                                        int util014(int x) { return x * 14 + 14; }
                                        int util015(int x) { return x * 15 + 15; }
                                        int util016(int x) { return x * 16 + 16; }
                                        int util017(int x) { return x * 17 + 17; }
                                        int util018(int x) { return x * 18 + 18; }
                                        int util019(int x) { return x * 19 + 19; }
                                        int util020(int x) { return x * 20 + 20; }
                                        int util021(int x) { return x * 21 + 21; }
                                        int util022(int x) { return x * 22 + 22; }
                                        int util023(int x) { return x * 23 + 23; }
                                        int util024(int x) { return x * 24 + 24; }
                                        int util025(int x) { return x * 25 + 25; }
                                        int util026(int x) { return x * 26 + 26; }
                                        int util027(int x) { return x * 27 + 27; }
                                        int util028(int x) { return x * 28 + 28; }
                                        int util029(int x) { return x * 29 + 29; }
                                        int util030(int x) { return x * 30 + 30; }
                                        int util031(int x) { return x * 31 + 31; }
                                        int util032(int x) { return x * 32 + 32; }
                                        int util033(int x) { return x * 33 + 33; }
                                        int util034(int x) { return x * 34 + 34; }
                                        int util035(int x) { return x * 35 + 35; }
                                        int util036(int x) { return x * 36 + 36; }
                                        int util037(int x) { return x * 37 + 37; }
                                        int util038(int x) { return x * 38 + 38; }
                                        int util039(int x) { return x * 39 + 39; }
                                        int util040(int x) { return x * 40 + 40; }
                                        int util041(int x) { return x * 41 + 41; }
                                        int util042(int x) { return x * 42 + 42; }
                                        int util043(int x) { return x * 43 + 43; }
                                        int util044(int x) { return x * 44 + 44; }
                                        int util045(int x) { return x * 45 + 45; }
                                        int util046(int x) { return x * 46 + 46; }
                                        int util047(int x) { return x * 47 + 47; }
                                        int util048(int x) { return x * 48 + 48; }
                                        int util049(int x) { return x * 49 + 49; }
                                        int util050(int x) { return x * 50 + 50; }
                                        int util051(int x) { return x * 51 + 51; }
                                        int util052(int x) { return x * 52 + 52; }
                                        int util053(int x) { return x * 53 + 53; }
                                        int util054(int x) { return x * 54 + 54; }
                                        int util055(int x) { return x * 55 + 55; }
                                        int util056(int x) { return x * 56 + 56; }
                                        int util057(int x) { return x * 57 + 57; }
                                        int util058(int x) { return x * 58 + 58; }
                                        int util059(int x) { return x * 59 + 59; }
                                        int util060(int x) { return x * 60 + 60; }
                                        int util061(int x) { return x * 61 + 61; }
                                        int util062(int x) { return x * 62 + 62; }
                                        int util063(int x) { return x * 63 + 63; }
                                        int util064(int x) { return x * 64 + 64; }
                                        int util065(int x) { return x * 65 + 65; }
                                        int util066(int x) { return x * 66 + 66; }
                                        int util067(int x) { return x * 67 + 67; }
                                        int util068(int x) { return x * 68 + 68; }
                                        int util069(int x) { return x * 69 + 69; }
                                        int util070(int x) { return x * 70 + 70; }
                                        int util071(int x) { return x * 71 + 71; }
                                        int util072(int x) { return x * 72 + 72; }
                                        int util073(int x) { return x * 73 + 73; }
                                        int util074(int x) { return x * 74 + 74; }
                                        int util075(int x) { return x * 75 + 75; }
                                        int util076(int x) { return x * 76 + 76; }
                                        int util077(int x) { return x * 77 + 77; }
                                        int util078(int x) { return x * 78 + 78; }
                                        int util079(int x) { return x * 79 + 79; }
                                        int util080(int x) { return x * 80 + 80; }
                                        int util081(int x) { return x * 81 + 81; }
                                        int util082(int x) { return x * 82 + 82; }
                                        int util083(int x) { return x * 83 + 83; }
                                        int util084(int x) { return x * 84 + 84; }
                                        int util085(int x) { return x * 85 + 85; }
                                        int util086(int x) { return x * 86 + 86; }
                                        int util087(int x) { return x * 87 + 87; }
                                        int util088(int x) { return x * 88 + 88; }
                                        int util089(int x) { return x * 89 + 89; }
                                        int util090(int x) { return x * 90 + 90; }
                                        int util091(int x) { return x * 91 + 91; }
                                        int util092(int x) { return x * 92 + 92; }
                                        int util093(int x) { return x * 93 + 93; }
                                        int util094(int x) { return x * 94 + 94; }
                                        int util095(int x) { return x * 95 + 95; }
                                        int util096(int x) { return x * 96 + 96; }
                                        int util097(int x) { return x * 97 + 97; }
                                        int util098(int x) { return x * 98 + 98; }
                                        int util099(int x) { return x * 99 + 99; }
                                        int util100(int x) { return x * 100 + 100; }
                                    
                                        // more padding with loops and conditionals
                                        void processBatch1(std::vector<int>& data) {
                                            for (size_t i = 0; i < data.size(); ++i) {
                                                if (data[i] < 0) data[i] = 0;
                                                else if (data[i] > 1000) data[i] = 1000;
                                                data[i] = data[i] * 2 + 1;
                                            }
                                        }
                                    
                                        void processBatch2(std::vector<int>& data) {
                                            for (size_t i = 0; i < data.size(); ++i) {
                                                if (isEven(data[i])) data[i] += 10;
                                                else data[i] -= 5;
                                            }
                                        }
                                    
                                        void processBatch3(std::vector<float>& data) {
                                            for (size_t i = 0; i < data.size(); ++i) {
                                                data[i] = clampFloat(data[i], 0.0f, 1.0f);
                                                data[i] = data[i] * data[i];
                                            }
                                        }
                                    
                                        void fillSequence(std::vector<int>& out, int count) {
                                            out.clear();
                                            out.reserve(count);
                                            for (int i = 0; i < count; ++i) {
                                                out.push_back(i * 3 + 7);
                                            }
                                        }
                                    
                                        int sumRange(const std::vector<int>& v, int start, int end) {
                                            int s = 0;
                                            for (int i = start; i < end && i < static_cast<int>(v.size()); ++i) {
                                                s += v[i];
                                            }
                                            return s;
                                        }
                                    
                                        float average(const std::vector<float>& v) {
                                            if (v.empty()) return 0.0f;
                                            float s = 0.0f;
                                            for (float x : v) s += x;
                                            return s / static_cast<float>(v.size());
                                        }
                                    
                                        // large block of repetitive switch / if logic
                                        int classify(int value) {
                                            switch (value % 10) {
                                                case 0: return 100;
                                                case 1: return 101;
                                                case 2: return 102;
                                                case 3: return 103;
                                                case 4: return 104;
                                                case 5: return 105;
                                                case 6: return 106;
                                                case 7: return 107;
                                                case 8: return 108;
                                                case 9: return 109;
                                                default: return -1;
                                            }
                                        }
                                    
                                        int classify2(int value) {
                                            if (value < 0) return -1;
                                            if (value < 10) return 0;
                                            if (value < 20) return 1;
                                            if (value < 30) return 2;
                                            if (value < 40) return 3;
                                            if (value < 50) return 4;
                                            if (value < 60) return 5;
                                            if (value < 70) return 6;
                                            if (value < 80) return 7;
                                            if (value < 90) return 8;
                                            return 9;
                                        }
]]

local option = 2
return if option == 1 then { option1 } else { option2 }
