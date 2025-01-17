#ifndef AI_H
#define AI_H

#include <vector>
#include <cstdlib>
#include <ctime>
#include <iostream>

class AI {
public:
    // Constructor to initialize the AI with given number of states and actions
    AI(int states, int actions);

    // Choose an action using epsilon-greedy strategy
    int chooseAction(int state, double epsilon);

    // Update the Q-table based on the action taken, reward received, and next state
    void updateQTable(int state, int action, double reward, int nextState, double alpha, double gamma);

    // Print the Q-table (for debugging purposes)
    void printQTable();

private:
    int states;  // Number of states in the environment
    int actions; // Number of actions available in each state
    std::vector<std::vector<double>> qTable; // Q-table storing Q-values for each state-action pair
};

#endif // AI_H
