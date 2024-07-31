#include <arpa/inet.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/socket.h>
#include <unistd.h>
#define MAX 15
#define PORT 8081 // Port for clientA
#define SA struct sockaddr

void func(int sockfd) {
    char buff[MAX];
    int n;
    for (;;) {
        memset(buff, 0, sizeof(buff));
        printf("Enter your choice (0 for Rock, 1 for Paper, 2 for Scissors): ");
        scanf("%s",buff);
        // n = 0;
        // while ((buff[n++] = getchar()) != '\n')
        //     ;
        // write(sockfd, buff, sizeof(buff));
        send(sockfd,&buff,sizeof(buff),0);
        memset(buff, 0, sizeof(buff));
        recv(sockfd,&buff,sizeof(buff),0);
        printf("From Server: %s\n", buff);
        if (strncmp(buff, "ClientA wins!", 13) == 0 || strncmp(buff, "ClientB wins!", 13) == 0 || strncmp(buff, "It's a Draw!!",13)==0) {
            printf("Do you want to play another round? (yes/no): ");
            memset(buff, 0, sizeof(buff));
            scanf("%s",buff);
            // n = 0;
            // while ((buff[n++] = getchar()) != '\n')
            //     ;
            send(sockfd,&buff, sizeof(buff),0);
            memset(buff, 0, sizeof(buff));
            recv(sockfd,&buff,sizeof(buff),0);
            if (strncmp(buff, "Game Over!!!!", 13) == 0) {
                printf("Client Exit...\n");
                break;
            }
        }
    }
    // Close the socket
    close(sockfd);
}

int main() {
    int sockfd;
    struct sockaddr_in servaddr;

    // Socket create and verification
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd == -1) {
        printf("Socket creation failed...\n");
        exit(0);
    }

    memset(&servaddr, 0, sizeof(servaddr));

    // Assign IP, PORT
    servaddr.sin_family = AF_INET;
    servaddr.sin_addr.s_addr = inet_addr("127.0.0.1"); // Change to the server's IP address if necessary
    servaddr.sin_port = htons(PORT); // Port for clientA

    // Connect the client socket to the server socket
    if (connect(sockfd, (SA*)&servaddr, sizeof(servaddr)) != 0) {
        printf("Connection with the server failed...\n");
        exit(0);
    }

    // Function for the game
    func(sockfd);

    return 0;
}
