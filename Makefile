BIN_DIR := "./llama.cpp/build/bin"

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
	$(BIN_DIR)/rpc-server --device CUDA0 -p 50052

Qwen3-Coder-30B-A3B-Instruct-UD-Q8_K_XL.gguf:
	curl -O -L https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF/resolve/main/Qwen3-Coder-30B-A3B-Instruct-UD-Q8_K_XL.gguf?download=true

main: .bin Qwen3-Coder-30B-A3B-Instruct-UD-Q8_K_XL.gguf
	$(BIN_DIR)/llama-cli \
			--model Qwen3-Coder-30B-A3B-Instruct-UD-Q8_K_XL.gguf \
			-ngl 99 \ # amount of layers to offload to GPU
			--rpc 192.168.20.2:50052

