#include "AI.h"

AI::AI(int states, int actions) : states(states), actions(actions) {
    qTable.resize(states, std::vector<double>(actions, 0.0)); // Initialize Q-table
    std::srand(static_cast<unsigned int>(std::time(nullptr))); // Seed for randomness
}

int AI::chooseAction(int state, double epsilon) {
    if ((std::rand() % 100) < epsilon * 100) {
        // Exploration: Random action
        return std::rand() % actions;
    } else {
        // Exploitation: Best known action
        double maxQ = qTable[state][0];
        int action = 0;
        for (int i = 1; i < actions; ++i) {
            if (qTable[state][i] > maxQ) {
                maxQ = qTable[state][i];
                action = i;
            }
        }
        return action;
    }
}

void AI::updateQTable(int state, int action, double reward, int nextState, double alpha, double gamma) {
    double maxNextQ = *std::max_element(qTable[nextState].begin(), qTable[nextState].end());
    qTable[state][action] += alpha * (reward + gamma * maxNextQ - qTable[state][action]);
}

void AI::printQTable() {
    for (int i = 0; i < states; ++i) {
        for (int j = 0; j < actions; ++j) {
            std::cout << qTable[i][j] << " ";
        }
        std::cout << std::endl;
    }
}
