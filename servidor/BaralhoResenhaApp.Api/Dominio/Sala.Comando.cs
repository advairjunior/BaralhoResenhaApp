namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// O comando da sala: puxar, pular, revelar e tirar cartas é de uma pessoa só.
/// Ela pode passar para outra, e se o celular dela sumir o comando passa sozinho.
/// </summary>
public sealed partial class Sala
{
    /// <summary>
    /// Cada celular consulta a sala a cada 6 s; sem sinal por mais que isso, a
    /// bateria acabou ou a aba fechou. Folga para quem só deu uma olhada no WhatsApp.
    /// </summary>
    public static readonly TimeSpan TempoSemSinal = TimeSpan.FromSeconds(90);

    public void PassarComando(string token, Guid novoId)
    {
        lock (_trinco)
        {
            var atual = ExigirAnfitriao(token, "Só quem está no comando pode passar o comando.");
            var novo = _jogadores.FirstOrDefault(j => j.Id == novoId)
                ?? throw new AcaoNaoPermitidaException("Essa pessoa não está na sala.");
            atual.Anfitriao = false;
            novo.Anfitriao = true;
            Tocar();
        }
    }

    /// <summary>
    /// O celular disse que está aí. Se quem está no comando sumiu, o comando vai
    /// para o próximo da lista que ainda está na mesa.
    /// </summary>
    /// <returns>Se o comando mudou de mão (os outros celulares precisam saber).</returns>
    public bool MarcarPresenca(string token)
    {
        lock (_trinco)
        {
            Reconhecer(token);
            var atual = _jogadores.FirstOrDefault(j => j.Anfitriao);
            var agora = _relogio.GetUtcNow();
            if (atual is null || agora - atual.VistoEm <= TempoSemSinal) return false;
            var inicio = _jogadores.IndexOf(atual);
            var novo = Enumerable.Range(1, _jogadores.Count - 1)
                .Select(passo => _jogadores[(inicio + passo) % _jogadores.Count])
                .FirstOrDefault(j => agora - j.VistoEm <= TempoSemSinal);
            if (novo is null) return false;
            atual.Anfitriao = false;
            novo.Anfitriao = true;
            Tocar();
            return true;
        }
    }
}
