#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <unistd.h>

#define PORT_A 8080
#define PORT_B 8081
#define MAXLINE 1024

// Function to determine the game result
char* determineResult(int choiceA, int choiceB) {
    if (choiceA == choiceB) {
        return "Draw";
    } else if ((choiceA == 0 && choiceB == 2) || (choiceA == 1 && choiceB == 0) || (choiceA == 2 && choiceB == 1)) {
        return "Client A Wins";
    } else {
        return "Client B Wins";
    }
}

int main() {
    int sockfdA, sockfdB;
    char buffer[MAXLINE];
    struct sockaddr_in servaddrA, servaddrB;

    // Creating socket file descriptors
    if ((sockfdA = socket(AF_INET, SOCK_DGRAM, 0)) < 0 || (sockfdB = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        perror("socket creation failed");
        exit(EXIT_FAILURE);
    }

    memset(&servaddrA, 0, sizeof(servaddrA));
    memset(&servaddrB, 0, sizeof(servaddrB));

    // Filling server information for client A
    servaddrA.sin_family = AF_INET;
    servaddrA.sin_port = htons(PORT_A);
    servaddrA.sin_addr.s_addr = INADDR_ANY;

    // Filling server information for client B
    servaddrB.sin_family = AF_INET;
    servaddrB.sin_port = htons(PORT_B);
    servaddrB.sin_addr.s_addr = INADDR_ANY;

    // Bind the sockets with server addresses
    int option=1;
    setsockopt(sockfdA,SOL_SOCKET,SO_REUSEADDR,&option,sizeof(option));
    option=1;
    setsockopt(sockfdB,SOL_SOCKET,SO_REUSEADDR,&option,sizeof(option));
    if (bind(sockfdA, (const struct sockaddr*)&servaddrA, sizeof(servaddrA)) < 0 ||
        bind(sockfdB, (const struct sockaddr*)&servaddrB, sizeof(servaddrB)) < 0) {
        perror("bind failed");
        exit(EXIT_FAILURE);
    }

    printf("Server is waiting for clients...\n");

    while (1) {
        int choiceA, choiceB;
        char* result;
        socklen_t lenA = sizeof(servaddrA);
        socklen_t lenB = sizeof(servaddrB);

        // Receive choices from client A
        recvfrom(sockfdA, &choiceA, sizeof(int), 0, (struct sockaddr*)&servaddrA, &lenA);
        printf("Received choice from Client A: %d\n", choiceA);

        // Receive choices from client B
        recvfrom(sockfdB, &choiceB, sizeof(int), 0, (struct sockaddr*)&servaddrB, &lenB);
        printf("Received choice from Client B: %d\n", choiceB);

        // Determine the game result
        result = determineResult(choiceA, choiceB);

        // Send the result to both clients
        sendto(sockfdA, result, strlen(result), 0, (const struct sockaddr*)&servaddrA, lenA);
        sendto(sockfdB, result, strlen(result), 0, (const struct sockaddr*)&servaddrB, lenB);

        printf("Result sent to both clients: %s\n", result);

        // Ask clients if they want to play another game
        char playAgain1,playAgain2;
        recvfrom(sockfdA, &playAgain1, sizeof(char), 0, (struct sockaddr*)&servaddrA, &lenA);
        recvfrom(sockfdB, &playAgain2, sizeof(char), 0, (struct sockaddr*)&servaddrB, &lenB);

        if (playAgain1== 'N' || playAgain2 == 'N') {
            break;
        }
    }

    close(sockfdA);
    close(sockfdB);
    return 0;
}
