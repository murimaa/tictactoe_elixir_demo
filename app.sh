#!/bin/bash

# Tictactoe Phoenix App - Unified Management Script
# Usage: ./app.sh [command] [options]

set -e

# Configuration
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'main')"
APP_NAME="tictactoe_elixir_demo"

DOCKER_IMAGE="$APP_NAME:$GIT_BRANCH-latest"
CONTAINER_NAME="$APP_NAME-web"
DEV_CONTAINER_NAME="$APP_NAME-dev"
PORT="4000"
ENV_FILE=".env"

# Build configuration
BUILD_ENV="${BUILD_ENV:-prod}"
DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_NAMESPACE="${DOCKER_NAMESPACE}"
DOCKER_USERNAME="${DOCKER_USERNAME}"
DOCKER_PASSWORD="${DOCKER_PASSWORD}"
IMAGE_NAME="$DOCKER_REGISTRY/$DOCKER_NAMESPACE/$APP_NAME"
GIT_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d-%H%M%S)}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse options
SKIP_TESTS=false
PUSH_IMAGE=false
DEPLOY=false
VERBOSE=false

for arg in "$@"; do
    case $arg in
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --push-image)
            PUSH_IMAGE=true
            shift
            ;;
        --deploy)
            DEPLOY=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
    esac
done

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${PURPLE}==== $1 ====${NC}"
}

log_substep() {
    echo -e "${CYAN}---- $1 ----${NC}"
}

# Container management helper functions
container_exists() {
    local container_name="$1"
    docker ps -a --format "{{.Names}}" | grep -q "^${container_name}$"
}

container_running() {
    local container_name="$1"
    docker ps --format "{{.Names}}" | grep -q "^${container_name}$"
}

safe_container_stop() {
    local container_name="$1"
    if container_running "$container_name"; then
        docker stop "$container_name" 2>/dev/null || true
    fi
}

safe_container_remove() {
    local container_name="$1"
    if container_exists "$container_name"; then
        docker rm "$container_name" 2>/dev/null || true
    fi
}

# Check prerequisites
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

check_env_file() {
    if [ ! -f "$ENV_FILE" ]; then
        log_warning "Environment file $ENV_FILE not found."
        if [ -f ".env.example" ]; then
            log_info "Copying .env.example to $ENV_FILE"
            cp .env.example "$ENV_FILE"
            log_warning "Please edit $ENV_FILE with your configuration before deploying."
        else
            log_error "No environment file found. Please create $ENV_FILE"
            exit 1
        fi
    fi
}

# Generate secret key base if needed
generate_secret() {
    if command -v mix &> /dev/null; then
        mix phx.gen.secret
    else
        openssl rand -base64 64 | tr -d '\n'
    fi
}

# =============================================================================
# DEVELOPMENT COMMANDS
# =============================================================================

dev_start() {
    log_step "Starting Development Environment"
    check_docker

    log_info "Starting development server with hot reload..."

    if container_exists "$DEV_CONTAINER_NAME"; then
        log_info "Stopping existing development container..."
        safe_container_stop "$DEV_CONTAINER_NAME"
        safe_container_remove "$DEV_CONTAINER_NAME"
    fi

    # Check if we have docker compose
    if [ -f "docker-compose.yml" ]; then
        docker compose --profile dev up -d web-dev
        log_success "Development environment started with docker compose"
    else
        # Fallback to direct docker run
        docker run -d \
            --name "$DEV_CONTAINER_NAME" \
            -p "$PORT:4000" \
            -e MIX_ENV=dev \
            -e PHX_SERVER=true \
            -e SECRET_KEY_BASE="dev-secret-key-base" \
            -e PHX_HOST=localhost \
            -e PORT=4000 \
            -v "$(pwd):/app" \
            -v "/app/_build" \
            -v "/app/deps" \
            -v "/app/assets/node_modules" \
            --rm \
            "$DOCKER_IMAGE" \
            mix phx.server
        log_success "Development container started"
    fi

    log_info "Development server available at http://localhost:$PORT"
    log_info "Use 'app.sh dev-logs' to view logs"
    log_info "Use 'app.sh dev-stop' to stop"
}

dev_stop() {
    log_step "Stopping Development Environment"

    # Stop docker compose services
    if docker compose ps -q > /dev/null 2>&1; then
        docker compose --profile dev down
        log_success "docker compose development services stopped"
    fi

    # Stop direct container
    if container_exists "$DEV_CONTAINER_NAME"; then
        safe_container_stop "$DEV_CONTAINER_NAME"
        safe_container_remove "$DEV_CONTAINER_NAME"
        log_success "Development container stopped"
    fi

    if ! container_exists "$DEV_CONTAINER_NAME" && ! docker compose ps -q > /dev/null 2>&1; then
        log_info "No development environment running"
    fi
}

dev_logs() {
    log_info "Showing development logs..."

    if docker compose ps -q web-dev > /dev/null 2>&1; then
        docker compose logs -f web-dev
    elif container_running "$DEV_CONTAINER_NAME"; then
        docker logs -f "$DEV_CONTAINER_NAME"
    else
        log_error "No development environment running"
        log_info "Start with: app.sh dev-start"
        exit 1
    fi
}

dev_shell() {
    log_info "Opening development shell..."

    if container_running "$DEV_CONTAINER_NAME"; then
        docker exec -it "$DEV_CONTAINER_NAME" /bin/bash
    elif docker compose ps -q web-dev > /dev/null 2>&1; then
        docker compose exec web-dev /bin/bash
    else
        log_error "No development environment running"
        log_info "Start with: app.sh dev-start"
        exit 1
    fi
}

# =============================================================================
# QUALITY CHECK COMMANDS
# =============================================================================

quality_check() {
    log_step "Running Quality Checks"

    check_format
    check_compile
    run_tests
    check_security

    log_success "All quality checks passed! ✨"
}

check_format() {
    log_substep "Code Formatting Check"

    if command -v mix &> /dev/null; then
        if ! mix format --check-formatted; then
            log_error "Code is not properly formatted. Run 'mix format' to fix."
            exit 1
        fi
        log_success "Code formatting is correct"
    else
        log_warning "Mix not available, skipping format check"
    fi
}

check_compile() {
    log_substep "Compilation Check"

    if command -v mix &> /dev/null; then
        if ! mix compile --warnings-as-errors; then
            log_error "Compilation failed with warnings treated as errors"
            exit 1
        fi
        log_success "Compilation successful"
    else
        log_warning "Mix not available, skipping compile check"
    fi
}

run_tests() {
    if [ "$SKIP_TESTS" = true ]; then
        log_warning "Skipping tests (--skip-tests flag provided)"
        return 0
    fi

    log_substep "Running Tests"

    if command -v mix &> /dev/null; then
        export MIX_ENV=test
        mix deps.get --only test
        mix compile

        if ! mix test --cover --warnings-as-errors; then
            log_error "Tests failed"
            exit 1
        fi
        log_success "All tests passed"
    else
        log_warning "Mix not available, skipping tests"
    fi
}

check_security() {
    log_substep "Security Checks"

    if command -v mix &> /dev/null; then
        # Dependency audit
        if mix hex.audit 2>/dev/null; then
            mix deps.audit || log_warning "Dependency audit found issues"
        fi

        # Sobelow security scanner
        if mix archive.install hex sobelow --force 2>/dev/null; then
            mix sobelow || log_warning "Sobelow found security issues"
        fi
    else
        log_warning "Mix not available, skipping security checks"
    fi

    log_success "Security checks completed"
}

fix_format() {
    log_step "Fixing Code Format"

    if command -v mix &> /dev/null; then
        mix format
        log_success "Code formatted successfully"
    else
        log_error "Mix not available, cannot fix formatting"
        exit 1
    fi
}

# =============================================================================
# BUILD AND PRODUCTION COMMANDS
# =============================================================================

build_image() {
    log_step "Building Docker Image"
    check_docker

    log_info "Building image: $DOCKER_IMAGE"

    docker build \
        --build-arg BUILD_ENV="$BUILD_ENV" \
        --build-arg GIT_COMMIT="$GIT_COMMIT" \
        --build-arg BUILD_NUMBER="$BUILD_NUMBER" \
        --label "org.opencontainers.image.source=https://$DOCKER_REGISTRY/$DOCKER_NAMESPACE/$APP_NAME" \
        --label "org.opencontainers.image.revision=$GIT_COMMIT" \
        --label "org.opencontainers.image.created=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        -t "$DOCKER_IMAGE" \
        .

    log_success "Docker image built successfully"
    docker images "$APP_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
}

prod_start() {
    log_step "Starting Production Container"
    check_docker
    check_env_file

    # Stop existing container if running
    if container_exists "$CONTAINER_NAME"; then
        log_info "Stopping existing production container..."
        safe_container_stop "$CONTAINER_NAME"
        safe_container_remove "$CONTAINER_NAME"
    fi

    # Run new container
    docker run -d \
        --name "$CONTAINER_NAME" \
        --env-file "$ENV_FILE" \
        -p "$PORT:4000" \
        --restart unless-stopped \
        "$DOCKER_IMAGE"

    log_success "Production container started: $CONTAINER_NAME"
    log_info "Application available at http://localhost:$PORT"
}

prod_stop() {
    log_info "Stopping production container..."

    if container_exists "$CONTAINER_NAME"; then
        safe_container_stop "$CONTAINER_NAME"
        safe_container_remove "$CONTAINER_NAME"
        log_success "Production container stopped"
    else
        log_info "No production container running"
    fi
}

prod_logs() {
    log_info "Showing production logs..."

    if container_running "$CONTAINER_NAME"; then
        docker logs -f "$CONTAINER_NAME"
    else
        log_error "No production container running"
        log_info "Start with: app.sh prod-start"
        exit 1
    fi
}

release() {
    log_step "Building Release"

    # Run quality checks first (unless skipped)
    if [ "$SKIP_TESTS" != true ]; then
        quality_check
    fi

    # Build image
    build_image

    # Test the built image
    test_image

    # Push to registry if requested
    if [ "$PUSH_IMAGE" = true ]; then
        push_image
    fi

    log_success "Release build completed! 🚀"
}

test_image() {
    log_substep "Testing Docker Image"

    local test_port="14000"
    local test_container="$APP_NAME-test"

    # Clean up any existing test container
    safe_container_stop "$test_container"
    safe_container_remove "$test_container"

    # Start test container
    log_info "Starting test container..."
    docker run -d --name "$test_container" \
        -p "$test_port:4000" \
        -e PHX_SERVER=true \
        -e SECRET_KEY_BASE="test-secret-key-base-for-image-testing" \
        -e PHX_HOST=localhost \
        -e PORT=4000 \
        "$DOCKER_IMAGE"

    # Wait for container to start
    log_info "Waiting for application to start..."
    sleep 10

    # Health check
    if curl -f -s "http://localhost:$test_port/health" > /dev/null; then
        log_success "Docker image test passed"
    else
        docker logs "$test_container"
        log_error "Docker image test failed: http://localhost:$test_port/health"
        safe_container_stop "$test_container"
        safe_container_remove "$test_container"
        exit 1
    fi

    # Cleanup
    safe_container_stop "$test_container"
    safe_container_remove "$test_container"
}

push_image() {
    log_substep "Pushing to Registry"

    local image_tag="$IMAGE_NAME:$GIT_BRANCH-$GIT_COMMIT"
    local image_latest="$IMAGE_NAME:$GIT_BRANCH-latest"

    # Tag for registry
    log_info "Tagging Docker image: $DOCKER_IMAGE -> $image_tag, $image_latest"
    docker tag "$DOCKER_IMAGE" "$image_tag"
    docker tag "$DOCKER_IMAGE" "$image_latest"

    # Login to registry if credentials available
    if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
        log_info "Logging into Docker registry..."
        echo "$DOCKER_PASSWORD" | docker login "$DOCKER_REGISTRY" -u "$DOCKER_USERNAME" --password-stdin
    fi

    # Push images
    log_info "Pushing $image_tag..."
    docker push "$image_tag"

    log_info "Pushing $image_latest..."
    docker push "$image_latest"

    log_success "Images pushed to registry"
}

# =============================================================================
# UTILITY COMMANDS
# =============================================================================

setup_env() {
    log_step "Setting up Environment"

    if [ ! -f "$ENV_FILE" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example "$ENV_FILE"
        else
            cat > "$ENV_FILE" << EOF
PHX_SERVER=true
PHX_HOST=localhost
PORT=4000
MIX_ENV=prod
SECRET_KEY_BASE=$(generate_secret)
EOF
        fi
        log_success "Environment file created at $ENV_FILE"
        log_warning "Please review and update $ENV_FILE before deploying to production"
    else
        log_info "Environment file already exists at $ENV_FILE"
    fi
}

status() {
    log_step "System Status"

    echo ""
    log_info "=== Container Status ==="

    # Production container
    if container_exists "$CONTAINER_NAME"; then
        if container_running "$CONTAINER_NAME"; then
            log_success "Production container '$CONTAINER_NAME' is running"
            docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        else
            log_warning "Production container '$CONTAINER_NAME' exists but is not running"
        fi
    else
        log_info "No production container found"
    fi

    # Development container
    if container_exists "$DEV_CONTAINER_NAME"; then
        if container_running "$DEV_CONTAINER_NAME"; then
            log_success "Development container '$DEV_CONTAINER_NAME' is running"
            docker ps --filter "name=$DEV_CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        else
            log_warning "Development container '$DEV_CONTAINER_NAME' exists but is not running"
        fi
    else
        log_info "No development container found"
    fi

    # Docker Compose
    echo ""
    log_info "=== Docker Compose Services ==="
    if docker compose ps > /dev/null 2>&1; then
        docker compose ps
    else
        log_info "No docker compose services found"
    fi

    # Images
    echo ""
    log_info "=== Docker Images ==="
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${DOCKER_IMAGE}$"; then
        docker images --filter "reference=$APP_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    else
        log_info "No application images found"
    fi

    # System resources
    echo ""
    log_info "=== System Resources ==="
    docker system df
}

health() {
    log_info "Checking application health..."

    local url="http://localhost:$PORT"
    if curl -f -s "$url/health" > /dev/null; then
        log_success "Application is healthy and responding at $url"

        # Show health details if verbose
        if [ "$VERBOSE" = true ]; then
            log_info "Health check response:"
            curl -s "$url/health" | jq . 2>/dev/null || curl -s "$url/health"
        fi
    else
        log_error "Application is not responding at $url"
        exit 1
    fi
}

cleanup() {
    log_step "Cleaning Up Resources"

    # Stop all containers
    log_info "Stopping all containers..."
    dev_stop
    prod_stop

    # Remove images if they exist
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${DOCKER_IMAGE}$"; then
        docker rmi "$DOCKER_IMAGE" 2>/dev/null || {
            log_warning "Failed to remove image $DOCKER_IMAGE, it may be in use"
        }
    fi

    # Clean up Docker system
    docker system prune -f
    log_success "Cleanup completed"
}

show_help() {
    cat << EOF
${YELLOW}USAGE:${NC}
    $0 [command] [options]

${YELLOW}DEVELOPMENT COMMANDS:${NC}
    ${GREEN}dev-start${NC}        Start development environment with hot reload
    ${GREEN}dev-stop${NC}         Stop development environment
    ${GREEN}dev-logs${NC}         Show development logs (follow)
    ${GREEN}dev-shell${NC}        Open shell in development container

${YELLOW}QUALITY COMMANDS:${NC}
    ${GREEN}quality-check${NC}    Run all quality checks (format, compile, test, security)
    ${GREEN}check-format${NC}     Check code formatting
    ${GREEN}fix-format${NC}       Fix code formatting
    ${GREEN}test${NC}             Run tests only

${YELLOW}PRODUCTION COMMANDS:${NC}
    ${GREEN}build${NC}            Build Docker image
    ${GREEN}prod-start${NC}       Start production container
    ${GREEN}prod-stop${NC}        Stop production container
    ${GREEN}prod-logs${NC}        Show production logs (follow)
    ${GREEN}release${NC}          Full release pipeline (quality + build + test)

${YELLOW}UTILITY COMMANDS:${NC}
    ${GREEN}setup-env${NC}        Setup environment file (.env)
    ${GREEN}status${NC}           Show system status
    ${GREEN}health${NC}           Check application health
    ${GREEN}cleanup${NC}          Clean up all resources
    ${GREEN}help${NC}             Show this help

${YELLOW}OPTIONS:${NC}
    ${GREEN}--skip-tests${NC}     Skip test execution
    ${GREEN}--push-image${NC}     Push image to registry (release command)
    ${GREEN}--verbose, -v${NC}    Verbose output

${YELLOW}EXAMPLES:${NC}
    ${CYAN}# Daily development workflow${NC}
    $0 dev-start              # Start coding
    $0 dev-logs               # Debug issues
    $0 dev-stop               # End session

    ${CYAN}# Pre-commit workflow${NC}
    $0 fix-format             # Fix formatting
    $0 quality-check          # Run all checks

    ${CYAN}# Production deployment${NC}
    $0 setup-env              # One-time setup
    $0 release                # Build production version
    $0 prod-start             # Run in production mode
    $0 health                 # Verify it's working

    ${CYAN}# CI/CD workflow${NC}
    $0 release --push-image   # Full pipeline with registry push

${YELLOW}ENVIRONMENT:${NC}
    - Edit .env for configuration
    - Ensure Docker is running
    - For production: set proper SECRET_KEY_BASE and PHX_HOST

EOF
}

# =============================================================================
# MAIN COMMAND DISPATCHER
# =============================================================================

main() {
    local command="${1:-help}"

    case "$command" in
        # Development commands
        dev-start)
            dev_start
            ;;
        dev-stop)
            dev_stop
            ;;
        dev-logs)
            dev_logs
            ;;
        dev-shell)
            dev_shell
            ;;

        # Quality commands
        quality-check)
            quality_check
            ;;
        check-format)
            check_format
            ;;
        fix-format)
            fix_format
            ;;
        test)
            run_tests
            ;;

        # Production commands
        build)
            build_image
            ;;
        prod-start)
            prod_start
            ;;
        prod-stop)
            prod_stop
            ;;
        prod-logs)
            prod_logs
            ;;
        release)
            release
            ;;

        # Utility commands
        setup-env)
            setup_env
            ;;
        status)
            status
            ;;
        health)
            health
            ;;
        cleanup)
            cleanup
            ;;
        help|--help|-h)
            show_help
            ;;

        # Legacy aliases (for backwards compatibility)
        run-dev)
            log_warning "Command 'run-dev' is deprecated, use 'dev-start'"
            dev_start
            ;;
        run-prod)
            log_warning "Command 'run-prod' is deprecated, use 'prod-start'"
            prod_start
            ;;
        stop)
            log_warning "Command 'stop' is deprecated, use 'dev-stop' or 'prod-stop'"
            dev_stop
            prod_stop
            ;;
        logs)
            log_warning "Command 'logs' is deprecated, use 'dev-logs' or 'prod-logs'"
            if container_running "$DEV_CONTAINER_NAME" || docker compose ps -q web-dev > /dev/null 2>&1; then
                dev_logs
            else
                prod_logs
            fi
            ;;
        clean)
            log_warning "Command 'clean' is deprecated, use 'cleanup'"
            cleanup
            ;;
        deploy)
            log_warning "Command 'deploy' is deprecated, use 'release' then 'prod-start'"
            release
            prod_start
            ;;

        "")
            log_error "No command specified"
            show_help
            exit 1
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Handle script interruption
trap 'log_error "Script interrupted!"; exit 1' INT TERM

# Execute main function
main "$@"
