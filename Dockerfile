#
# MailHog Dockerfile
#
# Changes based on https://medium.com/@chemidy/create-the-smallest-and-secured-golang-docker-image-based-on-scratch-4752223b7324
# and https://medium.com/@diogok/on-golang-static-binaries-cross-compiling-and-plugins-1aed33499671
#

############################
# STEP 1 build executable binary
#############################
FROM golang:alpine as builder

# Compile STATIC MailHog:
RUN apk --no-cache add git \
  && mkdir -p /root/gocode \
  && export GOPATH=/root/gocode \
  && CGO_ENABLED=0 go get -ldflags '-w -extldflags "-static"' github.com/mailhog/MailHog

# Create appuser.
ENV USER=appuser
ENV UID=1000 

# See https://stackoverflow.com/a/55757473/12429735RUN 
RUN adduser \    
    --disabled-password \    
    --gecos "" \    
    --home "/nonexistent" \    
    --shell "/sbin/nologin" \    
    --no-create-home \    
    --uid "${UID}" \    
    "${USER}"


############################
# STEP 2 build a small image
############################
FROM scratch

# Import the user and group files from the builder.
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Copy our static executable.
COPY --from=builder /root/gocode/bin/MailHog /usr/local/bin/MailHog

# Use an unprivileged user.
USER appuser:appuser

# Run the binary.
ENTRYPOINT ["/usr/local/bin/MailHog"]

# Expose the SMTP and HTTP ports:
EXPOSE 1025 8025
