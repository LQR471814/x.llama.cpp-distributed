llama.cpp:
	git clone "https://github.com/ggml-org/llama.cpp.git" --depth 1

.bin: llama.cpp
	cd llama.cpp && \
		mkdir -p build && \
		cd build && \
		cmake .. -DGGML_CUDA=ON -DGGML_RPC=ON && \
		cmake --build . --config Release
	touch .bin

remote: .bin
	cd llama.cpp && \
		./bin/rpc-server --device CUDA0 -p 50052

main: .bin
	cd llama.cpp && \
		./bin/llama-cli \
			-hf unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF \
			-ngl 99 \ # amount of layers to offload to GPU
			--rpc 192.168.20.2:50052

