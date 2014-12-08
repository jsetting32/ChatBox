ChatBox
===============
A Mac Chatroom application built on top of GCDAsyncSocket.

![Screen Shot 2014-09-05 at 4.19.57 AM.png](https://bitbucket.org/repo/gxqLe4/images/1072281788-Screen%20Shot%202014-09-05%20at%204.19.57%20AM.png)


<h2>Usage</h2>

<h3>Basic Usage</h3>
First the server window should be running at all times on a computer. When the server is running, a randomly generated socket is chosen to be used for connectivity purposes for clients to communicate through. 
Once the server is up and running on a socket, the Client program can be run. The only information the Client needs is to know what socket and ip-address the Server is running on if the client is not running on the same machine as the server.
Once both the client and server are running, the server has several features that the SUPERuser can do. A broadcast message can be sent from the server to all clients. The superuser can also disconnect everyone from the server but the feature of booting specific clients from the server is unavailable at the moment.
A Client has the ability to join chatrooms, send whisper messages to specific people in the server, in a specific chatroom, broadcast lists of who is currently on the server, as well as retrieve lists of members who are currently in a chatroom. 
Each chatroom conversation is private to those within the chatroom, expect for the superuser whose listening in on the server-side. The server interface shows messages from all clients no matter whether the user is in a chatroom or in the lobby.
Each client, when logged into the server is pushed into the lobby. They have a choice of joining multiple chatrooms at a time, and removing them selves from a chatroom at their own desire. 

<br><br>
<h2>Author</h2>
- [John Setting](http://github.com/jsetting32) ([Facebook](https://www.facebook.com/jsetting23))
<br><br>
