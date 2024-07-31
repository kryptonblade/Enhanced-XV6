#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <unistd.h>

#define PORT_B 8081
#define MAXLINE 1024

int main() {
    int sockfd;
    struct sockaddr_in servaddr;
    char playAgain;

    // Creating socket file descriptor
    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        perror("socket creation failed");
        exit(EXIT_FAILURE);
    }

    memset(&servaddr, 0, sizeof(servaddr));

    // Filling server information
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons(PORT_B);
    servaddr.sin_addr.s_addr = INADDR_ANY;

    int choice;
    socklen_t len = sizeof(servaddr);

    do {
        printf("Enter your choice (0 for Rock, 1 for Paper, 2 for Scissors): ");
        scanf("%d", &choice);

        // Send choice to the server
        sendto(sockfd, &choice, sizeof(int), 0, (const struct sockaddr*)&servaddr, len);

        // Receive and print the result from the server
        char buffer[MAXLINE];
        recvfrom(sockfd, buffer, sizeof(buffer), 0, (struct sockaddr*)&servaddr, &len);
        printf("Result: %s\n", buffer);

        // Ask if the client wants to play again
        printf("Play again? (Y/N): ");
        scanf(" %c", &playAgain);
        sendto(sockfd, &playAgain, sizeof(char), 0, (const struct sockaddr*)&servaddr, len);

    } while (playAgain == 'Y' || playAgain == 'y');

    close(sockfd);
    return 0;
}
