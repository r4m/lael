HEADER_H=../../TmoteComm.h
BUILD_EXTRA_DEPS += OutputSaver.class

OutputSaver.class: $(wildcard *.java) Sensors.java Radio.java
	javac *.java

SensorsMsg.java: $(HEADER_H)
	mig -target=null -java-classname=Sensors java $(HEADER_H) sensors_msg -o $@

RadioMsg.java: $(HEADER_H)
	mig -target=null -java-classname=Radio java $(HEADER_H) radio_msg -o $@

clean:
	rm -f *.class $(GEN)

