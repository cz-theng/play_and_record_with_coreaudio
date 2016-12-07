#OpenAL对象属性
在前面的章节[播放裸数据](./player.html)中，介绍了OpenAL提供的几个最基本的对象：

* 装数据的Buffer
* 表示声源的Source
* 表示听众的Listener

那么OpenAL是如何通过这几个对象来营造丰富的3D效果呢？这就要从OpenAL为这些对象设计的属性来说起了。

## OpenAL函数风格
OpenAL实现一般是使用C来实现的，而其风格和OpenGL类似，为函数提供了诸如

	alBufferf   // 参数是个float
	alBuffer3f  // 参数是3个float
	alBufferfv  // 参数是个float指针
	alBufferi   // 参数是个int
	alBuffer3i  // 参数是3个int
	alBufferiv  // 参数是个int指针
	
这种`alXxxx[f/3f/fv/i/3i/iv]`的命名风格，初次接触可能不太容易理解，实际上就是一系列的Get和Set函数，比如：

	void alBufferf(      ALuint buffer,      ALenum param,      ALfloat value	);
如同：

	buffer.param = (float) value
OC中的setter。这里buffer表示一个Buffer对象，param表示对应的属性，将其赋值为一个float类型的value。而：

	void alBufferfv(      ALuint buffer,      ALenum param,      ALfloat *values	);	
如同：
	
	float value = buffer.parma 	
OC中的getter。同样buffer表示一个Buffer对象，param表示对应的属性，将其取出赋给float类型的value

## Buffer
OpenAL为Buffer设计的属性有：

属性| 类型 | 意义
AL_FREQUENCY | int| 采样率
AL_BITS |int | 位深度AL_CHANNELS |int| 通道数AL_SIZE | int| 数据大小
AL_DATA |int| 数据原始位置指针

### 创建和删除Buffer
创建Buffer的过程是通过调用接口由OpenAL来为我们创建：

	 void alGenBuffers(      ALsizei n,      ALuint *buffers	);
这里通过n来表示创建几个Buffer，Buffer对应的引用通过buffers的数组返回。

	void alDeleteBuffers(      ALsizei n,      ALuint *buffers	);
这个就是对应的删除方式，删除掉buffers数组中的Buffer对象。

当然，因为这两个方法都是void返回值的，所以需要去调用前面文章介绍“alGetError”来进行错误处理。

### 设置Buffer中的数据
Buffer创建好之后，本身是没有任何音频数据的，需要我们自己为其填充将要播放的数据：

	void alBufferData(      ALuint buffer,      ALenum format,      const ALvoid *data,      ALsizei size,      ALsizei freq	);
这里buffer表示要填充的Buffer对象，format是一个表示位深度的枚举，data为具体的PCM数据，size自然是PCM数据的长度，最后的freq是PCM数据的采样率。 format的枚举有	
* AL_FORMAT_MONO8 ： 8位的MONO数据* AL_FORMAT_MONO16 ： 16位MONO数据
* AL_FORMAT_STEREO8 ： 8为STEREO数据
* AL_FORMAT_STEREO16 ： 16位STEREO数据。

### 属性设置与查询
上面的填充数据一下子把最开始介绍的属性都设置了，如果发现此时给的值错了要怎么修改呢？或者怎么进行查询呢？因为上面我们介绍的属性都是int类型值，所以我们通过：

	alBufferi
	alBufferiv
来进行属性的访问。比如我们要查询采样率：

	int freq = 0;
	alBufferiv( buf, AL_ FREQUENCY, &freq);
	printf("frequency is %d", freq);

## Source
OpenAL为Source提供的属性有：

属性| 类型| 意义
AL_PITCH |int | 音高倍数AL_GAIN |float| 声音的增益
AL_MAX_DISTANCE| float|最远距离AL_ROLLOFF_FACTOR |float |衰减速率
AL_REFERENCE_DISTANCE |float| 声音音量降低一半的距离AL_MIN_GAIN|float|最小增益
AL_MAX_GAIN|float|最大增益
AL_CONE_OUTER_GAIN |float|不在音源朝向的位置的增益
AL_CONE_INNER_ANGLE|float|音源朝向位置的增益
AL_CONE_OUTER_ANGLE|float|音源朝向的外角度,默认360°AL_POSITION |3f|音源位置
AL_VELOCITY |3f|音源移动速度
AL_DIRECTION | 3f| 音源的方向向量AL_SOURCE_RELATIVE | int|表示音源是否相对于听众位子AL_SOURCE_TYPE |int|声源类型(AL_UNDETERMINED, AL_STATIC, or AL_STREAMING)AL_LOOPING|int|是否循环播放（AL_TRUE、AL_FALSE）
AL_BUFFER | int| 绑定的Buffer的ID
AL_SOURCE_STATE|int|声源的状态，是否在播放（AL_STOPPED, AL_PLAYING）AL_BUFFERS_QUEUED|int| 声源上绑定的Buffer的数目
AL_BUFFERS_PROCESSED|int|声源上绑定的已经处理的Buffer数目AL_SEC_OFFSET|float|当前播放位置，单位是s
AL_SAMPLE_OFFSET |float|当前播放位置，单位是采样率
AL_BYTE_OFFSET|float|当前播放位置，单位是byte

### 创建和销毁Source
同样Source也是由OpenAL来创建的：

	void alGenSources(      ALsizei n,      ALuint *sources	); 一样的，n表示创建几个Source，结果存在sources数组中。对应的销毁方法：

	void alDeleteSources(      ALsizei n,      ALuint *sources	);
销毁source数组中存放的n个Source对象。

因为他们都是void函数，所以判断成功也是需要用`alGetError`来进行判断。

### 属性获取和设置

Source提供了完整的：

	alSourcef 
	alSource3f 
	alSourcefv 
	alSourcei 
	alSource3i
	alSourceiv	alGetSourcef 
	alGetSource3f 
	alGetSourcefv 
	alGetSourcei 
	alGetSource3i 
	alGetSourceiv	
方法，可以对上面的属性进行操作和设置，比如要设置Source在Listenner的正前方。

	alSourcei(source, AL_SOURCE_RELATIVE, 1) 	alSourcei(source, AL_SOURCE_TYPE, AL_STATIC)
	alSource3f(source, AL_POSITION, 1,0,1) // x轴为正前方
先设置Source为相对Listener的，然后再设置其位置并且为静止不动的。	

### 播放控制

既然是声源，资源播放控制是通过他来实现的，播放这个声源、暂停播放这个声源。

	 void alSourcePlay( ALuint source);
	 void alSourcePause( ALuint source);
	 void alSourceStop( ALuint source);
	 void alSourceRewind( ALuint source);
四个函数分别表示：“播放”	 、“暂停”、“停止”、“重置”功能。这里注意了，“停止”后再播放，就会从开始的数据部分进行播放了，而“重置”也是先停止并设置为初始状态。

### 绑定Buffer
Buffre的数据要如何送入到Source中呢？Source通过一个对来来管理所有的Buffer，这些Buffer将按照FIFO的顺序依次进行播放。

	void alSourceQueueBuffers(      ALuint source,		 ALsizei n,      ALuint* buffers	);
这里讲buffers数组中的n个Buffer Enqueue到source的BufferQueue中。其相反动作自然是DeQueue

	void alSourceUnqueueBuffers(      ALuint source,		 ALsizei n,      ALuint* buffers	);	
将buffer数组中的n个Buffer对象从source的BufferQueue中Dequeued掉。	

## Listener
听众可以认为是扬声器，所以就只有一个表现，因此就不用去创建和销毁了。
Listener提供的属性有：

属性|类型|意义
---|---|---
AL_GAIN|float| 增益AL_POSITION|3f|位置
AL_VELOCITY|3f | 速度向量
AL_ORIENTATION|float array|前后朝向

### 属性获取和设置
Listener比较简单，只要设置其在空间中的位置和移动就可以了，所以其提供的所有函数都是用来设置和读取属性的：

	alListenerf 
	alListener3f 
	alListenerfv 
	alListeneri 
	alListener3i 
	alListeneriv 
	alGetListenerf 
	alGetListener3f 
	alGetListenerfv 
	alGetListeneri 
	alGetListener3i 
	alGetListeneriv
比如要设置其在原点朝向x轴方向：

	ALfloat listenerOri[] = { 1.0f, 0.0f, 0.0f, -1.0f, 0.0f, 0.0f };
	alListener3f(AL_POSITION, 0, 0, 0);
	alListener3f(AL_VELOCITY, 0, 0, 0);
	alListenerfv(AL_ORIENTATION, listenerOri);
这里首先设置位置为原点，速度为0禁止不动，然后用两个（x,y,z）		/(x/y/z)来表示朝向。


## 总结

OpenAL中通过设置Source和Listenner的相对位置，并往Source中输入音频数据，通过控制Source的播放与否就可以在Listener侧听到3D空间中的传来的声音了。当然OpenAL不仅仅只有这些接口，还有对State、Device等的设置，这里不一一列举，可以参考官方手册。

## 参考
1. [OpenAL_Programmers_Guide](https://www.openal.org/documentation/OpenAL_Programmers_Guide.pdf) 