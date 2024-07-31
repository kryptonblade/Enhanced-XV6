#include <stdio.h>
#include <netdb.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#define MAX 15
#define PORT_A 8080 // Port for client A
#define PORT_B 8081 // Port for client B
#define SA struct sockaddr

// Function for Rock, Paper, Scissors game logic
char* playRPS(char choiceA, char choiceB) {
    if (choiceA == choiceB)
        return "It's a Draw!!";
    else if (
        (choiceA == '0' && choiceB == '2') ||
        (choiceA == '2' && choiceB == '1') ||
        (choiceA == '1' && choiceB == '0')
    )
        return "ClientA wins!";
    else
        return "ClientB wins!";
}

// Function to handle game between two clients
void playGame(int connfdA, int connfdB) {
    char choiceA[MAX], choiceB[MAX];
    char cA,cB;
    char result[MAX];

    for (;;) {
        // Receive choices from clients
        recv(connfdA, &choiceA, sizeof(choiceA), 0);
        recv(connfdB, &choiceB, sizeof(choiceB), 0);

        printf("Client A chose: %s\n", choiceA);
        printf("Client B chose: %s\n", choiceB);
        cA=choiceA[0];
        cB=choiceB[0];
        // Determine the result of the game
        char* gameResult = playRPS(cA, cB);

        // Send the result to both clients`````````````````````````````             
        send(connfdA, gameResult, strlen(gameResult), 0);
        send(connfdB, gameResult, strlen(gameResult), 0);

        printf("Result: %s\n", gameResult);

        // Prompt clients for another game
        char playAgainA[MAX],playAgainB[MAX];
        recv(connfdA, &playAgainA, sizeof(playAgainA), 0);
        recv(connfdB, &playAgainB, sizeof(playAgainB), 0);

        if (playAgainA[0] == 'N' || playAgainB[0] == 'N') {
            char* game_end="Game Over!!!!";
            send(connfdA, game_end, strlen(game_end), 0);
            send(connfdB, game_end, strlen(game_end), 0);
            printf("Game Over.\n");
            break;
        }
        else{
            char* game_end1="Continuee!!!!";
            send(connfdA, game_end1, strlen(game_end1), 0);
            send(connfdB, game_end1, strlen(game_end1), 0);
        }
    }
}

int main() {
    int sockfdA, sockfdB, connfdA, connfdB, len;
    struct sockaddr_in servaddr, cliA, cliB;

    // Create socket for client A
    sockfdA = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfdA == -1) {
        printf("socket creation for client A failed...\n");
        exit(0);
    }

    // Create socket for client B
    sockfdB = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfdB == -1) {
        printf("socket creation for client B failed...\n");
        exit(0);
    }

    printf("Sockets successfully created for both clients.\n");

    memset(&servaddr, 0, sizeof(servaddr));

    // Assign IP and PORT for client A
    servaddr.sin_family = AF_INET;
    servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    servaddr.sin_port = htons(PORT_A);

    // Binding socket for client A
    int option=1;
    setsockopt(sockfdA,SOL_SOCKET,SO_REUSEADDR,&option,sizeof(option));
    if ((bind(sockfdA, (SA*)&servaddr, sizeof(servaddr))) != 0) {
        printf("socket bind for client A failed...\n");
        exit(0);
    }

    // Assign IP and PORT for client B
    servaddr.sin_port = htons(PORT_B);

    // Binding socket for client B
    option=1;
    setsockopt(sockfdB,SOL_SOCKET,SO_REUSEADDR,&option,sizeof(option));
    if ((bind(sockfdB, (SA*)&servaddr, sizeof(servaddr))) != 0) {
        printf("socket bind for client B failed...\n");
        exit(0);
    }

    printf("Sockets successfully binded for both clients.\n");

    // Listen for client A
    if ((listen(sockfdA, 5)) != 0) {
        printf("Listen for client A failed...\n");
        exit(0);
    }

    // Listen for client B
    if ((listen(sockfdB, 5)) != 0) {
        printf("Listen for client B failed...\n");
        exit(0);
    }

    printf("Server is listening for both clients...\n");

    len = sizeof(cliA);

    // Accept connection from client A
    connfdA = accept(sockfdA, (SA*)&cliA, &len);
    if (connfdA < 0) {
        printf("Server accept for client A failed...\n");
        exit(0);
    }

    printf("Server accepted client A...\n");

    len = sizeof(cliB);

    // Accept connection from client B
    connfdB = accept(sockfdB, (SA*)&cliB, &len);
    if (connfdB < 0) {
        printf("Server accept for client B failed...\n");
        exit(0);
    }

    printf("Server accepted client B...\n");

    // Start the Rock, Paper, Scissors game
    playGame(connfdA, connfdB);

    // Close the sockets
    close(sockfdA);
    close(sockfdB);

    return 0;
}
