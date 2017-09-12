import dnats.dnatsclient;

import core.thread;
import core.atomic;
import std.stdio;
import std.conv : to;
import std.datetime.stopwatch;


immutable uint messagesCount = 100000;

int main()
{
    auto clientAThread = new Thread({
        auto client = new NATSClient();

        // Connect with default settings:
        client.connect((in ServerInfo serverInfo){
            for (uint i = 0; i < messagesCount; ++i)
            {
                client.publish("COMMON", "Hello! This is a message #" ~ to!string(i));
            }
        });

        Thread.sleep(dur!("msecs")(80)); // Wait for subscriber
        client.runIOLoop(()=>client.totalMessagesSent == messagesCount);
        
        writeln("Total messages count sent: ", client.totalMessagesSent);
    });

    auto clientBThread = new Thread({
        auto client = new NATSClient();

        void onConnect(in ServerInfo serverInfo)
        {
            client.subscribe("COMMON", "SUBS1", (in NATSMessage msg){
                assert(msg.msg == "Hello! This is a message #" ~ to!string(client.totalMessagesReceived - 1));
            });
        }

        client.connect(&onConnect);
        client.runIOLoop(()=>client.totalMessagesReceived == messagesCount);
    });

    clientBThread.start();
    clientAThread.start();

    auto sw = StopWatch(AutoStart.yes);

    clientAThread.join();
    clientBThread.join();

    writeln("Took: ", sw.peek().total!"msecs", "ms");
    return 0;
}